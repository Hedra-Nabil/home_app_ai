import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_result_model.dart';

abstract class VoiceRemoteDataSource {
  Future<VoiceResultModel> startListening();
  Future<VoiceResultModel> stopListening();
  Stream<VoiceResultModel> get voiceStream;
}

class VoiceRemoteDataSourceImpl implements VoiceRemoteDataSource {
  final SpeechToText speechToText;
  final StreamController<VoiceResultModel> _controller =
      StreamController<VoiceResultModel>.broadcast();
  bool _isInitialized = false;

  VoiceRemoteDataSourceImpl(this.speechToText) {
    speechToText.statusListener = (status) {
      print('🎤 Speech status: $status');
    };
    speechToText.errorListener = (error) {
      print('❌ Speech error: $error');
      _controller.addError(error);
    };
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      print('🔄 Initializing speech recognition...');
      try {
        _isInitialized = await speechToText.initialize(
          onError: (error) {
            print('❌ Speech initialization error: ${error.errorMsg}');
          },
          onStatus: (status) {
            print('📊 Speech status during init: $status');
          },
        );

        if (_isInitialized) {
          print('✅ Speech recognition initialized successfully');
          // Check available locales
          final locales = await speechToText.locales();
          print(
            '🌍 Available locales: ${locales.map((l) => l.localeId).join(", ")}',
          );
        } else {
          print('❌ Speech recognition initialization failed');
          print(
            '💡 Make sure Google app is installed and updated on your device',
          );
        }
      } catch (e) {
        print('❌ Exception during initialization: $e');
        _isInitialized = false;
      }
    }
  }

  @override
  Future<VoiceResultModel> startListening() async {
    await _ensureInitialized();

    if (!_isInitialized) {
      throw Exception(
        'Speech recognition not available. Please check microphone permissions.',
      );
    }

    print('🎤 Starting to listen...');
    await speechToText.listen(
      onResult: (result) {
        print('📝 Recognized: ${result.recognizedWords}');
        final model = VoiceResultModel(
          recognizedText: result.recognizedWords,
          isListening: !result.finalResult,
        );
        _controller.add(model);
      },
      localeId: 'en_US', // Default to English, will be changed by VoiceBloc
      listenMode: ListenMode.confirmation,
    );
    return VoiceResultModel(recognizedText: '', isListening: true);
  }

  @override
  Future<VoiceResultModel> stopListening() async {
    await speechToText.stop();
    return VoiceResultModel(
      recognizedText: speechToText.lastRecognizedWords,
      isListening: false,
    );
  }

  @override
  Stream<VoiceResultModel> get voiceStream => _controller.stream;
}
