import '../../domain/entities/voice_result.dart';

class VoiceResultModel extends VoiceResult {
  const VoiceResultModel({
    required super.recognizedText,
    required super.isListening,
  });

  factory VoiceResultModel.fromEntity(VoiceResult entity) {
    return VoiceResultModel(
      recognizedText: entity.recognizedText,
      isListening: entity.isListening,
    );
  }

  VoiceResult toEntity() {
    return VoiceResult(
      recognizedText: recognizedText,
      isListening: isListening,
    );
  }
}
