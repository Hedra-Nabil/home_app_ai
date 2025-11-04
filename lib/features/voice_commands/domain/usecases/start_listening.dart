import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/voice_result.dart';
import '../repositories/voice_repository.dart';

class StartListeningUsecase implements UseCase<VoiceResult, NoParams> {
  final VoiceRepository repository;

  StartListeningUsecase(this.repository);

  @override
  Future<Either<Failure, VoiceResult>> call(NoParams params) async {
    return await repository.startListening();
  }
}
