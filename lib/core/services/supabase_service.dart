import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(String url, String anonKey)
    : _client = SupabaseClient(url, anonKey);

  Future<void> updateDeviceState(
    String deviceId, {
    bool? led1,
    bool? led2,
    bool? fanOn,
    bool? buzzerOn,
    bool? doorLocked,
    int? servoAngle,
  }) async {
    try {
      print('🔄 SupabaseService: Updating device state for: $deviceId');

      // نجيب الحالة الحالية الأول
      final currentState = await getDeviceState(deviceId);

      // نبني الـ data بناءً على الحالة الحالية + التحديثات الجديدة
      final data = <String, dynamic>{
        'device_id': deviceId,
        'updated_at': DateTime.now().toIso8601String(),
        // نحتفظ بالقيم القديمة
        'led1': led1 ?? currentState?['led1'] ?? false,
        'led2': led2 ?? currentState?['led2'] ?? false,
        'fan_on': fanOn ?? currentState?['fan_on'] ?? false,
        'buzzer_on': buzzerOn ?? currentState?['buzzer_on'] ?? false,
        'door_locked': doorLocked ?? currentState?['door_locked'] ?? true,
        'servo_angle': servoAngle ?? currentState?['servo_angle'] ?? 0,
      };

      print(
        '📝 SupabaseService: Data to insert (merged with current state): $data',
      );

      final insertResponse = await _client
          .from('iot_control')
          .insert(data)
          .select();
      print('✅ SupabaseService: Insert response: $insertResponse');
      print('✅ New device state inserted with full state preserved');
    } catch (e, stackTrace) {
      print('❌ SupabaseService: Failed to insert device state: $e');
      print('📚 SupabaseService: Stack trace: $stackTrace');
      throw Exception('Failed to insert device state: $e');
    }
  }

  Future<Map<String, dynamic>?> getSensorData(String deviceId) async {
    try {
      final response = await _client
          .from('iot_data')
          .select('*')
          .eq('device_id', deviceId)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();
      print('📊 Sensor data: $response');
      return response;
    } catch (e) {
      print('❌ Failed to fetch sensor data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDeviceState(String deviceId) async {
    try {
      final response = await _client
          .from('iot_control')
          .select('*')
          .eq('device_id', deviceId)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();
      print('📊 Current state: $response');
      return response;
    } catch (e) {
      print('❌ Failed to fetch device state: $e');
      return null;
    }
  }

  Future<void> saveCommand(
    String command,
    String action,
    int confidence,
    String response,
  ) async {
    try {
      await _client.from('voice_commands').insert({
        'command': command,
        'action': action,
        'confidence': confidence,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save command: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentCommands() async {
    try {
      final response = await _client
          .from('voice_commands')
          .select('*')
          .order('timestamp', ascending: false)
          .limit(10);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch commands: $e');
    }
  }

  // حفظ معلومات النظام والموقع
  Future<void> saveSystemInfo({
    required String deviceId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final data = {
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // إضافة معلومات الوقت والتاريخ
      final dateTime = deviceInfo['dateTime'];
      if (dateTime != null) {
        data['date'] = dateTime['formattedDate'];
        data['time'] = dateTime['formattedTime'];
        data['day_name'] = dateTime['dayName'];
      }

      // إضافة معلومات الموقع
      final location = deviceInfo['location'];
      if (location?['success'] == true) {
        data['latitude'] = location['latitude'];
        data['longitude'] = location['longitude'];
        data['city'] = location['city'];
        data['country'] = location['country'];
      }

      // إضافة معلومات الطقس
      final weather = deviceInfo['weather'];
      if (weather?['success'] == true) {
        data['temperature'] = weather['temperature'];
        data['humidity'] = weather['humidity'];
        data['wind_speed'] = weather['windSpeed'];
        data['weather_description'] = weather['weatherDescription'];
      }

      await _client.from('system_info').insert(data);
      print('✅ System info saved successfully');
    } catch (e) {
      print('❌ Failed to save system info: $e');
      throw Exception('Failed to save system info: $e');
    }
  }

  // جلب آخر معلومات النظام
  Future<Map<String, dynamic>?> getLatestSystemInfo(String deviceId) async {
    try {
      final response = await _client
          .from('system_info')
          .select('*')
          .eq('device_id', deviceId)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Failed to fetch system info: $e');
      return null;
    }
  }
}
