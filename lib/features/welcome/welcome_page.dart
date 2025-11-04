import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../settings/settings_bloc.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomePage({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final lang = settings.persona.language;
        final userName = settings.userName;

        // إذا في اسم، نعرضه في الترحيب
        final title = userName != null && userName.isNotEmpty
            ? (lang == 'ar' ? 'مرحباً $userName' : 'Welcome\n$userName')
            : (lang == 'ar' ? 'منزلك متصل' : 'Connected\nliving,');

        final subtitle = (lang == 'ar') ? 'تحكم سهل' : 'effortless\ncontrol.';
        final button = (lang == 'ar') ? 'ابدأ' : "Let's started";

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 32 : 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 32,
                          fontWeight: FontWeight.w400,
                          color: Colors.blueAccent,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      elevation: 8,
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 14 : 18,
                        horizontal: isSmallScreen ? 24 : 32,
                      ),
                    ),
                    onPressed: onStart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_open,
                          color: Colors.blueAccent,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          button,
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blueAccent,
                          size: isSmallScreen ? 16 : 20,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 32 : 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
