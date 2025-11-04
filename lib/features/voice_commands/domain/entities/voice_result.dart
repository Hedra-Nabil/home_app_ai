import 'package:equatable/equatable.dart';

class VoiceResult extends Equatable {
  final String recognizedText;
  final bool isListening;

  const VoiceResult({required this.recognizedText, required this.isListening});

  @override
  List<Object> get props => [recognizedText, isListening];
}
