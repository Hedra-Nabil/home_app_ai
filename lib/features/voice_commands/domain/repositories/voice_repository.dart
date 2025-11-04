import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/voice_result.dart';

abstract class VoiceRepository {
  Future<Either<Failure, VoiceResult>> startListening();
  Future<Either<Failure, VoiceResult>> stopListening();
  Stream<VoiceResult> get voiceStream;
}
