import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DeviceInfoService {
  // الحصول على الموقع الحالي
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'success': false, 'error': 'Location services are disabled'};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'success': false, 'error': 'Location permission denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'error': 'Location permission permanently denied',
        };
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // الحصول على اسم المكان
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String cityName = placemarks.first.locality ?? 'Unknown';
      String countryName = placemarks.first.country ?? 'Unknown';

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'city': cityName,
        'country': countryName,
        'fullAddress': '${placemarks.first.street}, $cityName, $countryName',
      };
    } catch (e) {
      print('❌ Location error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // الحصول على حالة الطقس
  Future<Map<String, dynamic>> getWeatherInfo(double lat, double lon) async {
    try {
      // استخدام Open-Meteo API (مجاني بدون API key)
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        return {
          'success': true,
          'temperature': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'windSpeed': current['wind_speed_10m'],
          'weatherCode': current['weather_code'],
          'weatherDescription': _getWeatherDescription(current['weather_code']),
        };
      } else {
        return {
          'success': false,
          'error': 'Weather API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Weather error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // الحصول على الوقت والتاريخ
  Map<String, dynamic> getCurrentDateTime() {
    final now = DateTime.now();

    return {
      'dateTime': now,
      'formattedDate': DateFormat('yyyy-MM-dd').format(now),
      'formattedTime': DateFormat('HH:mm:ss').format(now),
      'formattedDateTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      'arabicDate': DateFormat('dd/MM/yyyy').format(now),
      'arabicTime': DateFormat('hh:mm a', 'ar').format(now),
      'dayName': DateFormat('EEEE').format(now),
      'monthName': DateFormat('MMMM').format(now),
      'year': now.year,
      'month': now.month,
      'day': now.day,
      'hour': now.hour,
      'minute': now.minute,
      'second': now.second,
      'timestamp': now.millisecondsSinceEpoch,
    };
  }

  // الحصول على كل معلومات الجهاز
  Future<Map<String, dynamic>> getAllDeviceInfo() async {
    final dateTime = getCurrentDateTime();
    final location = await getCurrentLocation();

    Map<String, dynamic> weather = {'success': false};
    if (location['success'] == true) {
      weather = await getWeatherInfo(
        location['latitude'],
        location['longitude'],
      );
    }

    return {'dateTime': dateTime, 'location': location, 'weather': weather};
  }

  // وصف حالة الطقس من الكود
  String _getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear sky - سماء صافية';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy - غائم جزئياً';
      case 45:
      case 48:
        return 'Foggy - ضباب';
      case 51:
      case 53:
      case 55:
        return 'Drizzle - رذاذ';
      case 61:
      case 63:
      case 65:
        return 'Rain - مطر';
      case 71:
      case 73:
      case 75:
        return 'Snow - ثلج';
      case 80:
      case 81:
      case 82:
        return 'Rain showers - زخات مطر';
      case 95:
        return 'Thunderstorm - عاصفة رعدية';
      default:
        return 'Unknown - غير معروف';
    }
  }

  // تنسيق المعلومات للعرض
  String formatDeviceInfoForDisplay(Map<String, dynamic> info) {
    StringBuffer sb = StringBuffer();

    // الوقت والتاريخ
    final dt = info['dateTime'];
    sb.writeln('📅 التاريخ: ${dt['arabicDate']}');
    sb.writeln('🕐 الوقت: ${dt['arabicTime']}');
    sb.writeln('📆 اليوم: ${dt['dayName']}');
    sb.writeln();

    // الموقع
    final location = info['location'];
    if (location['success'] == true) {
      sb.writeln('📍 الموقع: ${location['city']}, ${location['country']}');
      sb.writeln(
        '🗺️ الإحداثيات: ${location['latitude'].toStringAsFixed(4)}, ${location['longitude'].toStringAsFixed(4)}',
      );
      sb.writeln();
    }

    // الطقس
    final weather = info['weather'];
    if (weather['success'] == true) {
      sb.writeln('🌡️ درجة الحرارة: ${weather['temperature']}°C');
      sb.writeln('💧 الرطوبة: ${weather['humidity']}%');
      sb.writeln('💨 سرعة الرياح: ${weather['windSpeed']} km/h');
      sb.writeln('🌤️ الحالة: ${weather['weatherDescription']}');
    }

    return sb.toString();
  }
}
