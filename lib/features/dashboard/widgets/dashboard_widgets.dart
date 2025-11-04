import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/supabase_service.dart';
import '../../settings/settings_bloc.dart';
import '../../voice_commands/presentation/blocs/voice_bloc.dart';
import '../../voice_commands/presentation/blocs/voice_event.dart';

/// بطاقة جهاز قابلة للتحكم (LED، Fan، Door)
class DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOn;
  final String deviceKey;
  final IconData icon;
  final String? extra;
  final ValueChanged<bool> onChanged;

  const DeviceCard({
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.deviceKey,
    required this.icon,
    required this.onChanged,
    this.extra,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          gradient: LinearGradient(
            colors: isOn
                ? [const Color(0xFF1A237E), const Color(0xFF3949AB)]
                : [Colors.grey[100]!, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isSmallScreen),
              const Spacer(),
              _buildTitle(isSmallScreen),
              SizedBox(height: isSmallScreen ? 2 : 4),
              _buildSubtitle(isSmallScreen),
              if (extra != null) _buildExtra(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          icon,
          color: isOn ? Colors.white : Colors.grey[600],
          size: isSmallScreen ? 24 : 28,
        ),
        const Spacer(),
        Transform.scale(
          scale: isSmallScreen ? 0.85 : 1.0,
          child: Switch(
            value: isOn,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white38,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: isOn ? Colors.white : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(bool isSmallScreen) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: isSmallScreen ? 12 : 14,
        color: isOn ? Colors.white70 : Colors.grey[600],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExtra(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 4 : 8),
        Text(
          extra!,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            color: isOn ? Colors.white : const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// بطاقة سنسور للقراءة فقط (Temperature، Humidity)
class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SensorCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.blue[700],
                size: isSmallScreen ? 28 : 32,
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper لتحديث حالة الجهاز في قاعدة البيانات
class DeviceUpdateHelper {
  static Future<void> updateDevice({
    required BuildContext context,
    required String deviceKey,
    required bool value,
  }) async {
    try {
      final supabaseService = context.read<SupabaseService>();

      switch (deviceKey) {
        case 'led1':
          await supabaseService.updateDeviceState(
            'esp32s3-C54908',
            led1: value,
          );
          break;
        case 'led2':
          await supabaseService.updateDeviceState(
            'esp32s3-C54908',
            led2: value,
          );
          break;
        case 'fan':
          await supabaseService.updateDeviceState(
            'esp32s3-C54908',
            fanOn: value,
          );
          break;
        case 'door':
          await supabaseService.updateDeviceState(
            'esp32s3-C54908',
            doorLocked: !value,
            servoAngle: value ? 90 : 0,
          );
          break;
      }

      print('✅ Dashboard: Device updated successfully');
    } catch (e) {
      print('❌ Dashboard: Failed to update: $e');
    }
  }

  static void sendVoiceCommand({
    required BuildContext context,
    required String deviceKey,
    required bool value,
  }) {
    String command = '';

    switch (deviceKey) {
      case 'led1':
        command = value ? 'turn on LED 1' : 'turn off LED 1';
        break;
      case 'led2':
        command = value ? 'turn on LED 2' : 'turn off LED 2';
        break;
      case 'fan':
        command = value ? 'turn on fan' : 'turn off fan';
        break;
      case 'door':
        command = value ? 'open door' : 'close door';
        break;
    }

    if (command.isNotEmpty) {
      context.read<VoiceBloc>().add(TextCommandEvent(command));
    }
  }
}

/// Dialog لتعديل اسم المستخدم
class EditNameDialog extends StatelessWidget {
  final String currentName;

  const EditNameDialog({required this.currentName, super.key});

  static Future<void> show(BuildContext context, String currentName) {
    return showDialog(
      context: context,
      builder: (dialogContext) => EditNameDialog(currentName: currentName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: currentName);

    return AlertDialog(
      title: const Text('Edit Your Name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _saveName(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveName(BuildContext dialogContext, String name) {
    if (name.trim().isEmpty) return;

    // Get the root context before popping
    final rootContext = Navigator.of(
      dialogContext,
      rootNavigator: true,
    ).context;

    rootContext.read<SettingsCubit>().setUserName(name.trim());
    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text('Name updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
