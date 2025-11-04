import 'package:equatable/equatable.dart';

import '../../domain/entities/voice_result.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object> get props => [];
}

class VoiceInitial extends VoiceState {}

class VoiceLoading extends VoiceState {}

class VoiceListening extends VoiceState {
  final VoiceResult result;

  const VoiceListening(this.result);

  @override
  List<Object> get props => [result];
}

class VoiceError extends VoiceState {
  final String message;

  const VoiceError(this.message);

  @override
  List<Object> get props => [message];
}

class VoiceSuccess extends VoiceState {
  final String command;
  final String action;
  final int confidence;
  final String response;

  const VoiceSuccess({
    required this.command,
    required this.action,
    required this.confidence,
    required this.response,
  });

  @override
  List<Object> get props => [command, action, confidence, response];
}
