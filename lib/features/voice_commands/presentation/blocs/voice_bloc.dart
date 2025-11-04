import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_app/core/services/gemini_service.dart';
import 'package:home_app/core/services/supabase_service.dart';
import 'package:home_app/core/services/text_to_speech_service.dart';
import 'package:home_app/core/services/user_cache_service.dart';
import 'package:home_app/core/services/device_info_service.dart';
import 'package:home_app/features/settings/settings_bloc.dart';

import '../../domain/repositories/voice_repository.dart';
import 'voice_event.dart';
import 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final VoiceRepository repository;
  final GeminiService geminiService;
  final SupabaseService supabaseService;
  final TextToSpeechService ttsService;
  final UserCacheService userCacheService;
  final SettingsCubit settingsCubit;
  final DeviceInfoService deviceInfoService = DeviceInfoService();
  StreamSubscription? _subscription;

  VoiceBloc(
    this.repository,
    this.geminiService,
    this.supabaseService,
    this.ttsService,
    this.userCacheService,
    this.settingsCubit,
  ) : super(VoiceInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<VoiceResultEvent>(_onVoiceResult);
    on<TextCommandEvent>(_onTextCommand);
  }

  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<VoiceState> emit,
  ) async {
    emit(VoiceLoading());
    try {
      final result = await repository.startListening();
      result.fold(
        (failure) {
          String errorMsg = failure.toString();
          // Provide helpful error messages
          if (errorMsg.contains('not available')) {
            errorMsg =
                'Speech recognition is not available. Please:\n'
                '1. Check microphone permissions\n'
                '2. Make sure Google app is installed\n'
                '3. Enable voice input in device settings';
          }
          emit(VoiceError(errorMsg));
        },
        (voiceResult) {
          emit(VoiceListening(voiceResult));
          // Listen to stream for updates
          _subscription?.cancel();
          _subscription = repository.voiceStream.listen((result) {
            add(VoiceResultEvent(result));
          });
        },
      );
    } catch (e) {
      print('❌ Exception in _onStartListening: $e');
      emit(VoiceError('Failed to start voice recognition: $e'));
    }
  }

  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<VoiceState> emit,
  ) async {
    // Cancel subscription immediately to stop listening
    _subscription?.cancel();

    emit(VoiceLoading());
    final result = await repository.stopListening();
    result.fold((failure) => emit(VoiceError(failure.toString())), (
      voiceResult,
    ) async {
      // If no text was recognized, just go back to initial state
      if (voiceResult.recognizedText.isEmpty) {
        emit(VoiceInitial());
        return;
      }

      // Process the voice command with Gemini AI
      final persona = settingsCubit.state.persona;
      final userName = settingsCubit.state.userName;
      final customName = settingsCubit.state.customPersonaName;

      final prompt = geminiService.buildPrompt(
        command: voiceResult.recognizedText,
        persona: persona.name,
        language: persona.language,
        userName: userName,
        personaName: customName,
        gender: persona.gender,
        nationality: persona.nationality,
        personality: persona.personality,
      );
      final geminiResponse = await geminiService.processPrompt(prompt);

      final parsed = _parseGeminiResponse(geminiResponse);

      // Handle user name if extracted
      if (parsed['user_name'] != null && parsed['user_name'] != 'null') {
        await userCacheService.saveUserInfo(
          'user_name',
          parsed['user_name'] as String,
        );
        settingsCubit.setUserName(parsed['user_name'] as String);
      }

      // Handle language switch if requested
      if (parsed['language_switch'] != null &&
          parsed['language_switch'] != 'null') {
        final newLang = parsed['language_switch'] as String;
        final newPersona = SettingsCubit.availablePersonas.firstWhere(
          (p) => p.language == newLang,
          orElse: () => persona,
        );
        settingsCubit.setPersona(newPersona);
      }

      await _updateDeviceState(parsed['action'] as String);

      // Generate status response if requested
      String finalResponse = parsed['response'] as String;
      if (parsed['action'] == 'status_all' ||
          parsed['action'] == 'what_is_on') {
        finalResponse = await _generateStatusResponse();
      }

      // Save command to database
      try {
        await supabaseService.saveCommand(
          voiceResult.recognizedText,
          parsed['action'] as String,
          parsed['confidence'] as int,
          finalResponse,
        );
      } catch (e) {
        print('Failed to save command: $e');
      }

      // Ensure TTS uses the selected language
      await ttsService.setLanguage(persona.language);
      await ttsService.speak(finalResponse);

      emit(
        VoiceSuccess(
          command: voiceResult.recognizedText,
          action: parsed['action'] as String,
          confidence: parsed['confidence'] as int,
          response: finalResponse,
        ),
      );
    });
  }

  void _onVoiceResult(VoiceResultEvent event, Emitter<VoiceState> emit) {
    emit(VoiceListening(event.result));
  }

  Future<void> _onTextCommand(
    TextCommandEvent event,
    Emitter<VoiceState> emit,
  ) async {
    emit(VoiceLoading());

    // Process the text command with Gemini AI
    final persona = settingsCubit.state.persona;
    final userName = settingsCubit.state.userName;
    final customName = settingsCubit.state.customPersonaName;

    final prompt = geminiService.buildPrompt(
      command: event.command,
      persona: persona.name,
      language: persona.language,
      userName: userName,
      personaName: customName,
      gender: persona.gender,
      nationality: persona.nationality,
      personality: persona.personality,
    );
    final geminiResponse = await geminiService.processPrompt(prompt);

    final parsed = _parseGeminiResponse(geminiResponse);

    // Handle user name if extracted
    if (parsed['user_name'] != null && parsed['user_name'] != 'null') {
      await userCacheService.saveUserInfo(
        'user_name',
        parsed['user_name'] as String,
      );
      settingsCubit.setUserName(parsed['user_name'] as String);
    }

    // Handle language switch if requested
    if (parsed['language_switch'] != null &&
        parsed['language_switch'] != 'null') {
      final newLang = parsed['language_switch'] as String;
      final newPersona = SettingsCubit.availablePersonas.firstWhere(
        (p) => p.language == newLang,
        orElse: () => persona,
      );
      settingsCubit.setPersona(newPersona);
    }

    await _updateDeviceState(parsed['action'] as String);

    // Generate status response if requested
    String finalResponse = parsed['response'] as String;
    if (parsed['action'] == 'status_all' || parsed['action'] == 'what_is_on') {
      finalResponse = await _generateStatusResponse();
    }

    // Save command to database
    try {
      await supabaseService.saveCommand(
        event.command,
        parsed['action'] as String,
        parsed['confidence'] as int,
        finalResponse,
      );
    } catch (e) {
      print('Failed to save command: $e');
    }

    // Ensure TTS uses the selected language
    await ttsService.setLanguage(persona.language);
    await ttsService.speak(finalResponse);

    emit(
      VoiceSuccess(
        command: event.command,
        action: parsed['action'] as String,
        confidence: parsed['confidence'] as int,
        response: finalResponse,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Map<String, dynamic> _parseGeminiResponse(String response) {
    try {
      // Simple JSON parsing (assuming the response is JSON-like)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        return {
          'action': 'unknown',
          'confidence': 0,
          'response': 'Command not understood',
          'user_name': null,
          'language_switch': null,
        };
      }
      final jsonString = response.substring(jsonStart, jsonEnd + 1);

      // Basic parsing without json.decode for simplicity
      final action = _extractAction(jsonString);
      final confidence = _extractConfidence(jsonString);
      final resp = _extractResponse(jsonString);
      final userName = _extractUserName(jsonString);
      final languageSwitch = _extractLanguageSwitch(jsonString);

      return {
        'action': action,
        'confidence': confidence,
        'response': resp,
        'user_name': userName,
        'language_switch': languageSwitch,
      };
    } catch (e) {
      return {
        'action': 'error',
        'confidence': 0,
        'response': 'Error parsing response: $e',
        'user_name': null,
        'language_switch': null,
      };
    }
  }

  String _extractAction(String json) {
    final actionMatch = RegExp(r'"action"\s*:\s*"([^"]*)"').firstMatch(json);
    return actionMatch?.group(1) ?? 'unknown';
  }

  int _extractConfidence(String json) {
    final confidenceMatch = RegExp(
      r'"confidence"\s*:\s*(\d+)',
    ).firstMatch(json);
    return int.tryParse(confidenceMatch?.group(1) ?? '0') ?? 0;
  }

  String _extractResponse(String json) {
    final responseMatch = RegExp(
      r'"response"\s*:\s*"([^"]*)"',
    ).firstMatch(json);
    return responseMatch?.group(1) ?? 'Command not understood';
  }

  String? _extractUserName(String json) {
    final userNameMatch = RegExp(
      r'"user_name"\s*:\s*"([^"]*)"',
    ).firstMatch(json);
    final name = userNameMatch?.group(1);
    return (name == null || name == 'null' || name.isEmpty) ? null : name;
  }

  String? _extractLanguageSwitch(String json) {
    final langMatch = RegExp(
      r'"language_switch"\s*:\s*"([^"]*)"',
    ).firstMatch(json);
    final lang = langMatch?.group(1);
    return (lang == null || lang == 'null' || lang.isEmpty) ? null : lang;
  }

  Future<void> _updateDeviceState(String action) async {
    const deviceId = 'esp32s3-C54908';

    // Get current state first
    final currentState = await supabaseService.getDeviceState(deviceId);

    bool? led1;
    bool? led2;
    bool? fanOn;
    bool? buzzerOn;
    bool? doorLocked;
    int? servoAngle;

    // Parse action and update states
    switch (action) {
      // LED Controls
      case 'led1_on':
        led1 = true;
        break;
      case 'led1_off':
        led1 = false;
        break;
      case 'led2_on':
        led2 = true;
        break;
      case 'led2_off':
        led2 = false;
        break;
      case 'both_on':
        led1 = true;
        led2 = true;
        break;
      case 'both_off':
        led1 = false;
        led2 = false;
        break;

      // Door Controls
      case 'door_open':
        doorLocked = false;
        servoAngle = 90; // Open position
        break;
      case 'door_close':
        doorLocked = true;
        servoAngle = 0; // Closed position
        break;
      case 'door_toggle':
        final currentLocked = currentState?['door_locked'] ?? true;
        doorLocked = !currentLocked;
        servoAngle = doorLocked ? 0 : 90;
        break;

      // Fan Controls
      case 'fan_on':
        fanOn = true;
        break;
      case 'fan_off':
        fanOn = false;
        break;
      case 'fan_toggle':
        final currentFan = currentState?['fan_on'] ?? false;
        fanOn = !currentFan;
        break;

      // Buzzer Controls
      case 'buzzer_on':
      case 'alert':
        buzzerOn = true;
        break;
      case 'buzzer_off':
        buzzerOn = false;
        break;

      // Smart Scenes
      case 'home_mode':
        led1 = true;
        led2 = true;
        doorLocked = true;
        fanOn = false;
        buzzerOn = false;
        servoAngle = 0;
        break;
      case 'away_mode':
        led1 = false;
        led2 = false;
        doorLocked = true;
        fanOn = false;
        buzzerOn = true; // Alarm on
        servoAngle = 0;
        break;
      case 'night_mode':
        led1 = false;
        led2 = true; // Bedroom light on
        doorLocked = true;
        fanOn = true;
        buzzerOn = false;
        servoAngle = 0;
        break;

      // Status Queries
      case 'status_all':
      case 'what_is_on':
        // This will be handled by returning current state in response
        return;

      // System Info Queries
      case 'get_temperature':
      case 'get_humidity':
      case 'get_location':
      case 'get_weather':
      case 'get_time':
        // Save device info to database when requested
        final deviceInfo = await deviceInfoService.getAllDeviceInfo();
        await supabaseService.saveSystemInfo(
          deviceId: deviceId,
          deviceInfo: deviceInfo,
        );
        return;

      default:
        // Unknown action, do nothing
        return;
    }

    // Update database with changed values only
    await supabaseService.updateDeviceState(
      deviceId,
      led1: led1,
      led2: led2,
      fanOn: fanOn,
      buzzerOn: buzzerOn,
      doorLocked: doorLocked,
      servoAngle: servoAngle,
    );
  }

  Future<String> _generateStatusResponse() async {
    const deviceId = 'esp32s3-C54908';
    final state = await supabaseService.getDeviceState(deviceId);
    final sensorData = await supabaseService.getSensorData(deviceId);
    final persona = settingsCubit.state.persona;

    if (state == null) {
      return persona.language == 'ar'
          ? 'عذراً، لا أستطيع الوصول لحالة الأجهزة حالياً'
          : 'Sorry, I cannot access device status right now';
    }

    List<String> activeDevices = [];
    List<String> inactiveDevices = [];

    // Check each device
    if (state['led1'] == true) {
      activeDevices.add(
        persona.language == 'ar' ? 'إضاءة الصالة' : 'Living room light',
      );
    } else {
      inactiveDevices.add(
        persona.language == 'ar' ? 'إضاءة الصالة' : 'Living room light',
      );
    }

    if (state['led2'] == true) {
      activeDevices.add(
        persona.language == 'ar' ? 'إضاءة غرفة النوم' : 'Bedroom light',
      );
    } else {
      inactiveDevices.add(
        persona.language == 'ar' ? 'إضاءة غرفة النوم' : 'Bedroom light',
      );
    }

    if (state['fan_on'] == true) {
      activeDevices.add(persona.language == 'ar' ? 'المروحة' : 'Fan');
    } else {
      inactiveDevices.add(persona.language == 'ar' ? 'المروحة' : 'Fan');
    }

    final doorStatus = state['door_locked'] == true
        ? (persona.language == 'ar' ? 'الباب مقفل' : 'Door is locked')
        : (persona.language == 'ar' ? 'الباب مفتوح' : 'Door is unlocked');

    if (persona.language == 'ar') {
      String response = 'حالة المنزل الآن:\n\n';

      if (activeDevices.isNotEmpty) {
        response += '🟢 الأجهزة المشغلة:\n';
        for (var device in activeDevices) {
          response += '  • $device\n';
        }
      }

      if (inactiveDevices.isNotEmpty) {
        response += '\n⚫ الأجهزة المطفية:\n';
        for (var device in inactiveDevices) {
          response += '  • $device\n';
        }
      }

      response += '\n🚪 $doorStatus';

      if (sensorData != null) {
        final temp = sensorData['temperature'];
        final humidity = sensorData['humidity'];
        if (temp != null)
          response += '\n🌡️ الحرارة: ${temp.toStringAsFixed(1)}°س';
        if (humidity != null)
          response += '\n💧 الرطوبة: ${humidity.toStringAsFixed(0)}%';
      }

      return response;
    } else {
      String response = 'Home Status:\n\n';

      if (activeDevices.isNotEmpty) {
        response += '🟢 Active Devices:\n';
        for (var device in activeDevices) {
          response += '  • $device\n';
        }
      }

      if (inactiveDevices.isNotEmpty) {
        response += '\n⚫ Inactive Devices:\n';
        for (var device in inactiveDevices) {
          response += '  • $device\n';
        }
      }

      response += '\n🚪 $doorStatus';

      if (sensorData != null) {
        final temp = sensorData['temperature'];
        final humidity = sensorData['humidity'];
        if (temp != null)
          response += '\n🌡️ Temperature: ${temp.toStringAsFixed(1)}°C';
        if (humidity != null)
          response += '\n💧 Humidity: ${humidity.toStringAsFixed(0)}%';
      }

      return response;
    }
  }
}
