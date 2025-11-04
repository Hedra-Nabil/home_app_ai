import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../settings/settings_bloc.dart';
import 'blocs/voice_bloc.dart';
import 'blocs/voice_event.dart';
import 'blocs/voice_state.dart';

class VoiceAssistantPage extends StatefulWidget {
  final VoidCallback onBack;
  const VoiceAssistantPage({required this.onBack, super.key});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with TickerProviderStateMixin {
  String _response = '';
  bool _listening = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the mic button
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Wave animation for listening state
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    // Trigger first-time introduction if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsCubit = context.read<SettingsCubit>();
      if (settingsCubit.state.isFirstTime) {
        // Send a greeting command to trigger the introduction
        context.read<VoiceBloc>().add(
          TextCommandEvent('Hello, I am a new user'),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: widget.onBack,
        ),
        title: Text(
          'AI Voice Assistant',
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
      ),
      body: BlocListener<VoiceBloc, VoiceState>(
        listener: (context, state) {
          if (state is VoiceListening) {
            if (!_listening) {
              setState(() => _listening = true);
              _waveController.repeat(reverse: true);
            }
          } else if (state is VoiceSuccess) {
            setState(() {
              _response = state.response;
              _listening = false;
            });
            _waveController.stop();
            _waveController.reset();
            // Complete onboarding after first successful interaction
            final settingsCubit = context.read<SettingsCubit>();
            if (settingsCubit.state.isFirstTime) {
              settingsCubit.completeOnboarding();
            }
          } else if (state is VoiceError) {
            setState(() {
              _response = state.message;
              _listening = false;
            });
            _waveController.stop();
            _waveController.reset();

            // Show error dialog for better visibility
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Voice Recognition Error'),
                  ],
                ),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is VoiceInitial || state is VoiceLoading) {
            if (_listening) {
              setState(() => _listening = false);
              _waveController.stop();
              _waveController.reset();
            }
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Hello!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'How can I make your home smarter today?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_response.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          child: Text(
                            _response,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Spacer(),
            // Animated waveform visualization
            if (_listening)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final delay = index * 0.2;
                      final height =
                          30 +
                          (40 *
                              ((1 + _waveController.value - delay) % 1.0)
                                  .abs());
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.orangeAccent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            if (_listening) SizedBox(height: 24),

            // Microphone button with animated pulse
            Container(
              margin: EdgeInsets.only(bottom: 40),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated pulse rings
                  if (_listening)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 80 + (_pulseController.value * 40),
                          height: 80 + (_pulseController.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(
                                0.5 - _pulseController.value * 0.5,
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  // Main button
                  GestureDetector(
                    onLongPressStart: (_) {
                      if (!_listening) {
                        context.read<VoiceBloc>().add(StartListeningEvent());
                      }
                    },
                    onLongPressEnd: (_) {
                      if (_listening) {
                        context.read<VoiceBloc>().add(StopListeningEvent());
                      }
                    },
                    onLongPressCancel: () {
                      if (_listening) {
                        context.read<VoiceBloc>().add(StopListeningEvent());
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _listening
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : [Color(0xFF1A237E), Color(0xFF3949AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _listening
                                ? Colors.redAccent.withOpacity(0.6)
                                : Color(0xFF1A237E).withOpacity(0.4),
                            blurRadius: _listening ? 24 : 16,
                            spreadRadius: _listening ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _listening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Hold to speak',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
