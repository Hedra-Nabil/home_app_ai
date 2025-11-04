import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/voice_bloc.dart';
import '../blocs/voice_event.dart';
import '../blocs/voice_state.dart';

class VoiceCommandsPage extends StatefulWidget {
  const VoiceCommandsPage({super.key});

  @override
  State<VoiceCommandsPage> createState() => _VoiceCommandsPageState();
}

class _VoiceCommandsPageState extends State<VoiceCommandsPage> {
  String _commandResult = '';
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home AI'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.white],
          ),
        ),
        child: BlocListener<VoiceBloc, VoiceState>(
          listener: (context, state) {
            if (state is VoiceListening) {
              setState(() {
                _isListening = state.result.isListening;
              });
            } else if (state is VoiceSuccess) {
              setState(() {
                _commandResult =
                    '${state.response}\n\nAction: ${state.action}\nConfidence: ${state.confidence}%';
              });
            } else if (state is VoiceError) {
              setState(() {
                _commandResult = '❌ Error: ${state.message}';
              });
            }
          },
          child: BlocBuilder<VoiceBloc, VoiceState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Voice Input Section
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Voice Commands',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onLongPressStart: (_) {
                                context.read<VoiceBloc>().add(
                                  StartListeningEvent(),
                                );
                              },
                              onLongPressEnd: (_) {
                                context.read<VoiceBloc>().add(
                                  StopListeningEvent(),
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? Colors.red
                                      : Colors.deepPurple,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isListening
                                                  ? Colors.red
                                                  : Colors.deepPurple)
                                              .withOpacity(0.3),
                                      spreadRadius: 5,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isListening
                                  ? 'Listening... Speak now!'
                                  : 'Hold to Talk (Push to Talk)',
                              style: TextStyle(
                                color: _isListening ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          'LED1 On',
                          Icons.lightbulb,
                          () => context.read<VoiceBloc>().add(
                            TextCommandEvent('turn on led1'),
                          ),
                        ),
                        _buildActionButton(
                          'LED1 Off',
                          Icons.lightbulb_outline,
                          () => context.read<VoiceBloc>().add(
                            TextCommandEvent('turn off led1'),
                          ),
                        ),
                        _buildActionButton(
                          'LED2 On',
                          Icons.lightbulb,
                          () => context.read<VoiceBloc>().add(
                            TextCommandEvent('turn on led2'),
                          ),
                        ),
                        _buildActionButton(
                          'LED2 Off',
                          Icons.lightbulb_outline,
                          () => context.read<VoiceBloc>().add(
                            TextCommandEvent('turn off led2'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Results Display
                    if (_commandResult.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            _commandResult,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
