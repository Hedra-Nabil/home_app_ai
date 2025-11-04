import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class PersonaProfile extends Equatable {
  final String id;
  final String name;
  final String gender;
  final String nationality;
  final String language;
  final String personality;
  final String description;

  const PersonaProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.nationality,
    required this.language,
    required this.personality,
    required this.description,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    gender,
    nationality,
    language,
    personality,
    description,
  ];
}

class SettingsState extends Equatable {
  final PersonaProfile persona;
  final String? userName;
  final String? customPersonaName;
  final bool isFirstTime;

  const SettingsState({
    required this.persona,
    this.userName,
    this.customPersonaName,
    this.isFirstTime = true,
  });

  SettingsState copyWith({
    PersonaProfile? persona,
    String? userName,
    String? customPersonaName,
    bool? isFirstTime,
  }) {
    return SettingsState(
      persona: persona ?? this.persona,
      userName: userName ?? this.userName,
      customPersonaName: customPersonaName ?? this.customPersonaName,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }

  @override
  List<Object?> get props => [
    persona,
    userName,
    customPersonaName,
    isFirstTime,
  ];
}

class SettingsCubit extends Cubit<SettingsState> {
  static final List<PersonaProfile> availablePersonas = [
    const PersonaProfile(
      id: 'emma',
      name: 'Emma',
      gender: 'female',
      nationality: 'British',
      language: 'en',
      personality: 'friendly_professional',
      description: 'Warm, helpful, and professional British assistant',
    ),
    const PersonaProfile(
      id: 'layla',
      name: 'ليلى',
      gender: 'female',
      nationality: 'Egyptian',
      language: 'ar',
      personality: 'warm_caring',
      description: 'Caring and warm Egyptian assistant who speaks Arabic',
    ),
    const PersonaProfile(
      id: 'alex',
      name: 'Alex',
      gender: 'male',
      nationality: 'American',
      language: 'en',
      personality: 'casual_funny',
      description: 'Casual, funny American assistant with a relaxed vibe',
    ),
    const PersonaProfile(
      id: 'yuki',
      name: 'Yuki',
      gender: 'female',
      nationality: 'Japanese',
      language: 'en',
      personality: 'polite_formal',
      description: 'Polite and formal Japanese assistant',
    ),
    const PersonaProfile(
      id: 'omar',
      name: 'عمر',
      gender: 'male',
      nationality: 'Saudi',
      language: 'ar',
      personality: 'confident_helpful',
      description: 'Confident and helpful Saudi assistant',
    ),
  ];

  SettingsCubit() : super(SettingsState(persona: availablePersonas[0]));

  void setPersona(PersonaProfile persona) {
    emit(state.copyWith(persona: persona));
  }

  void setUserName(String name) {
    emit(state.copyWith(userName: name, isFirstTime: false));
  }

  void setCustomPersonaName(String name) {
    emit(state.copyWith(customPersonaName: name));
  }

  void completeOnboarding() {
    emit(state.copyWith(isFirstTime: false));
  }
}
