import 'package:equatable/equatable.dart';

import '../../domain/entities/voice_result.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object> get props => [];
}

class StartListeningEvent extends VoiceEvent {}

class StopListeningEvent extends VoiceEvent {}

class VoiceResultEvent extends VoiceEvent {
  final VoiceResult result;

  const VoiceResultEvent(this.result);

  @override
  List<Object> get props => [result];
}

class TextCommandEvent extends VoiceEvent {
  final String command;

  const TextCommandEvent(this.command);

  @override
  List<Object> get props => [command];
}
