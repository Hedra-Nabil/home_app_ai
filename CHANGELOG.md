# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-11-03

### 🎉 Major Update - Complete Redesign

#### Added
- **New AI Model**: Upgraded to `gemini-2.5-flash-native-audio-dialog` for better conversation quality
- **Animated Waveforms**: Real-time audio visualization during voice recognition
- **Pulse Effects**: Animated rings around microphone button when active
- **5 AI Personas**: Emma (British), Layla (Egyptian), Alex (American), Yuki (Japanese), Omar (Saudi)
- **Persona Profiles**: Rich persona system with name, gender, nationality, personality, and language
- **Custom Persona Names**: Users can give custom names to their chosen persona
- **Name Memory**: AI asks for user's name on first use and remembers it
- **Auto Language Switching**: Detects language confusion and offers to switch language/persona
- **First-time Onboarding**: Automatic introduction flow for new users
- **Enhanced Settings UI**: Beautiful persona selection cards with full details
- **Improved Dashboard**: Gradient backgrounds, modern device cards with active/inactive states
- **Better Color Scheme**: Professional dark blue to white gradients matching reference designs

#### Changed
- **Push-to-Talk**: Changed from tap-to-start to hold-to-speak interaction
- **Gemini Prompts**: Enhanced with persona context, user name, language switching logic
- **VoiceBloc**: Now passes 8 parameters to Gemini (vs 3 before) for richer context
- **UI Colors**: Updated to professional palette with `#1A237E` primary color
- **Settings Page**: Complete redesign with persona cards instead of dropdowns
- **Welcome Page**: Now uses persona language for localized text
- **Dashboard Cards**: Now show active state with gradient backgrounds

#### Enhanced
- **Response Parsing**: Extracts `user_name` and `language_switch` from Gemini responses
- **TTS Language**: Automatically sets correct locale (ar-SA, en-US) based on persona
- **State Management**: Enhanced SettingsState with userName, customPersonaName, isFirstTime
- **Visual Feedback**: Mic button changes color and glow intensity when listening
- **Navigation**: First-time users automatically go to Voice Assistant for onboarding

#### Technical
- Clean Architecture maintained across all features
- Bloc pattern for state management
- Proper null safety handling
- Animation controllers for smooth effects
- Gradient decorations for modern UI

### Bug Fixes
- Fixed language detection in welcome page
- Fixed persona attribute passing to Gemini
- Fixed null safety issues in settings page
- Fixed TTS language synchronization

## [1.0.0] - 2025-11-01

### Initial Release

#### Features
- Basic voice command recognition
- Gemini AI integration with gemini-2.5-flash
- Supabase database for IoT control
- LED control (LED 1, LED 2)
- Text-to-Speech responses
- Simple settings (persona and language)
- Basic dashboard with device cards
- Welcome screen
- Voice assistant page

#### Tech Stack
- Flutter ^3.9.2
- google_generative_ai ^0.4.7
- supabase_flutter ^2.0.0
- speech_to_text ^6.3.0
- flutter_tts ^3.8.3
- flutter_bloc ^8.1.3

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)
