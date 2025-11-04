import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class SpeechFailure extends Failure {
  final String message;

  const SpeechFailure(this.message);

  @override
  List<Object> get props => [message];
}
