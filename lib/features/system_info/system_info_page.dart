import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/device_info_service.dart';
import '../../core/services/supabase_service.dart';

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await _deviceInfoService.getAllDeviceInfo();
      setState(() {
        _deviceInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToDatabase() async {
    if (_deviceInfo == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = context.read<SupabaseService>();
      await supabaseService.saveSystemInfo(
        deviceId: 'esp32s3-C54908',
        deviceInfo: _deviceInfo!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ System info saved to database!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          'System Information',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDeviceInfo,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (_isLoading || _deviceInfo == null)
                ? null
                : _saveToDatabase,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDeviceInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _deviceInfo == null
            ? const Center(
                child: Text('No data', style: TextStyle(color: Colors.white)),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '📅 Date & Time',
                      _buildDateTimeInfo(),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '📍 Location',
                      _buildLocationInfo(),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '🌤️ Weather',
                      _buildWeatherInfo(),
                      isSmallScreen,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content, bool isSmallScreen) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    final dateTime = _deviceInfo?['dateTime'];
    if (dateTime == null) return const Text('No date/time data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('📆 Date', dateTime['formattedDate'] ?? '--'),
        _buildInfoRow('🕐 Time', dateTime['formattedTime'] ?? '--'),
        _buildInfoRow('📅 Day', dateTime['dayName'] ?? '--'),
        _buildInfoRow('📅 Month', dateTime['monthName'] ?? '--'),
        _buildInfoRow('⏰ Timestamp', dateTime['timestamp']?.toString() ?? '--'),
      ],
    );
  }

  Widget _buildLocationInfo() {
    final location = _deviceInfo?['location'];
    if (location == null || location['success'] != true) {
      return Text(
        location?['error'] ?? 'No location data',
        style: const TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('🌍 City', location['city'] ?? '--'),
        _buildInfoRow('🏳️ Country', location['country'] ?? '--'),
        _buildInfoRow(
          '📍 Latitude',
          location['latitude']?.toStringAsFixed(6) ?? '--',
        ),
        _buildInfoRow(
          '📍 Longitude',
          location['longitude']?.toStringAsFixed(6) ?? '--',
        ),
        _buildInfoRow('🗺️ Address', location['fullAddress'] ?? '--'),
      ],
    );
  }

  Widget _buildWeatherInfo() {
    final weather = _deviceInfo?['weather'];
    if (weather == null || weather['success'] != true) {
      return Text(
        weather?['error'] ?? 'No weather data',
        style: const TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('🌡️ Temperature', '${weather['temperature']}°C'),
        _buildInfoRow('💧 Humidity', '${weather['humidity']}%'),
        _buildInfoRow('💨 Wind Speed', '${weather['windSpeed']} km/h'),
        _buildInfoRow('🌤️ Condition', weather['weatherDescription'] ?? '--'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
