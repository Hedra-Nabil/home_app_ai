import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../core/services/supabase_service.dart';
import '../settings/settings_bloc.dart';
import '../settings/settings_page.dart';
import '../system_info/system_info_page.dart';
import '../voice_commands/presentation/blocs/voice_bloc.dart';
import '../voice_commands/presentation/blocs/voice_state.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onVoice;
  const DashboardPage({required this.onVoice, super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool led1On = false;
  bool led2On = false;
  bool fanOn = false;
  bool doorLocked = true;
  double? temperature;
  double? humidity;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _loadDeviceState();
    _loadSensorData();

    // مزامنة تلقائية كل ثانية
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadDeviceState();
      _loadSensorData();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceState() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final deviceState = await supabaseService.getDeviceState(
        'esp32s3-C54908',
      );
      if (deviceState != null && mounted) {
        setState(() {
          // دلوقتي آخر صف دايماً فيه كل الأجهزة
          led1On = deviceState['led1'] ?? false;
          led2On = deviceState['led2'] ?? false;
          fanOn = deviceState['fan_on'] ?? false;
          doorLocked = deviceState['door_locked'] ?? true;
        });
        print(
          '✅ Device state loaded: LED1=$led1On, LED2=$led2On, Fan=$fanOn, Door=$doorLocked',
        );
      }
    } catch (e) {
      print('❌ Failed to load device state: $e');
    }
  }

  Future<void> _loadSensorData() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final sensorData = await supabaseService.getSensorData('esp32s3-C54908');
      if (sensorData != null && mounted) {
        setState(() {
          temperature = sensorData['temperature']?.toDouble();
          humidity = sensorData['humidity']?.toDouble();
        });
      }
    } catch (e) {
      print('Failed to load sensor data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return BlocListener<VoiceBloc, VoiceState>(
      listener: (context, state) => _handleVoiceStateChange(state),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: _buildBody(isSmallScreen),
      ),
    );
  }

  void _handleVoiceStateChange(VoiceState state) {
    if (state is! VoiceSuccess) return;

    final action = state.action.toLowerCase();
    setState(() {
      _updateDevicesFromAction(action);
    });
    // نحدث من قاعدة البيانات للتأكد من المزامنة
    _loadDeviceState();
    _loadSensorData();
  }

  void _updateDevicesFromAction(String action) {
    if (action.contains('led1')) {
      led1On = action.contains('on');
    } else if (action.contains('led2')) {
      led2On = action.contains('on');
    } else if (action.contains('both')) {
      led1On = led2On = action.contains('on');
    } else if (action.contains('fan')) {
      fanOn = action.contains('on');
    } else if (action.contains('door')) {
      doorLocked = action.contains('close') || action.contains('lock');
    } else if (action.contains('home_mode')) {
      led1On = led2On = true;
      doorLocked = true;
      fanOn = false;
    } else if (action.contains('away_mode')) {
      led1On = led2On = false;
      doorLocked = true;
      fanOn = false;
    } else if (action.contains('night_mode')) {
      led1On = false;
      led2On = true;
      doorLocked = true;
      fanOn = true;
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A237E),
      elevation: 0,
      title: const Text(
        'Smart Home',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'System Info',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SystemInfoPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.center,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 16 : 24),
          _buildWelcomeHeader(isSmallScreen),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Expanded(child: _buildDeviceGrid(isSmallScreen)),
          _buildVoiceButton(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isSmallScreen) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final userName = settings.userName ?? 'Guest';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'Welcome home,',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  color: Colors.white70,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.white70,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: () => EditNameDialog.show(context, userName),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceGrid(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallScreen ? 24 : 32),
          topRight: Radius.circular(isSmallScreen ? 24 : 32),
        ),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 12 : 16,
        childAspectRatio: isSmallScreen ? 0.85 : 1.0,
        children: [
          DeviceCard(
            title: 'LED 1',
            subtitle: 'Living room',
            isOn: led1On,
            deviceKey: 'led1',
            icon: Icons.lightbulb,
            onChanged: (val) => _handleDeviceToggle('led1', val),
          ),
          DeviceCard(
            title: 'LED 2',
            subtitle: 'Bedroom',
            isOn: led2On,
            deviceKey: 'led2',
            icon: Icons.lightbulb_outline,
            onChanged: (val) => _handleDeviceToggle('led2', val),
          ),
          DeviceCard(
            title: 'Fan',
            subtitle: 'Living room',
            isOn: fanOn,
            deviceKey: 'fan',
            icon: Icons.air,
            onChanged: (val) => _handleDeviceToggle('fan', val),
          ),
          DeviceCard(
            title: 'Door',
            subtitle: doorLocked ? 'Locked' : 'Unlocked',
            isOn: !doorLocked,
            deviceKey: 'door',
            icon: doorLocked ? Icons.lock : Icons.lock_open,
            onChanged: (val) => _handleDeviceToggle('door', val),
          ),
          SensorCard(
            title: 'Temperature',
            value: temperature != null
                ? '${temperature!.toStringAsFixed(1)}°C'
                : '--',
            icon: Icons.thermostat,
          ),
          SensorCard(
            title: 'Humidity',
            value: humidity != null ? '${humidity!.toStringAsFixed(0)}%' : '--',
            icon: Icons.water_drop,
          ),
          DeviceCard(
            title: 'AC',
            subtitle: 'Living room',
            isOn: false,
            deviceKey: 'ac',
            icon: Icons.ac_unit,
            extra: '24°',
            onChanged: (val) => _handleDeviceToggle('ac', val),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 18,
              horizontal: isSmallScreen ? 32 : 40,
            ),
            elevation: 8,
          ),
          icon: Icon(Icons.mic, size: isSmallScreen ? 24 : 28),
          label: Text(
            'Voice Assistant',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
          ),
          onPressed: widget.onVoice,
        ),
      ),
    );
  }

  void _handleDeviceToggle(String deviceKey, bool value) async {
    setState(() {
      switch (deviceKey) {
        case 'led1':
          led1On = value;
          break;
        case 'led2':
          led2On = value;
          break;
        case 'fan':
          fanOn = value;
          break;
        case 'door':
          doorLocked = !value;
          break;
      }
    });

    await DeviceUpdateHelper.updateDevice(
      context: context,
      deviceKey: deviceKey,
      value: value,
    );

    // نحدث من قاعدة البيانات بعد التحديث للتأكد من المزامنة
    await _loadDeviceState();
  }
}
