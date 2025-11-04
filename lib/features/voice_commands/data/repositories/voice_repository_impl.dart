import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/voice_result.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/voice_remote_data_source.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final VoiceRemoteDataSource remoteDataSource;

  VoiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, VoiceResult>> startListening() async {
    try {
      final result = await remoteDataSource.startListening();
      return Right(result.toEntity());
    } catch (e) {
      return Left(SpeechFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoiceResult>> stopListening() async {
    try {
      final result = await remoteDataSource.stopListening();
      return Right(result.toEntity());
    } catch (e) {
      return Left(SpeechFailure(e.toString()));
    }
  }

  @override
  Stream<VoiceResult> get voiceStream {
    return remoteDataSource.voiceStream.map((model) => model.toEntity());
  }
}
