# 🎤 شرح رحلة الأمر الصوتي - Voice Assistant Flow

## نظرة عامة
هذا المستند يشرح بالتفصيل ماذا يحدث عندما تتحدث مع المساعد الصوتي في تطبيق Smart Home.

---

## 🎯 الخطوات التفصيلية

### 1️⃣ الضغط على زر الميكروفون

**الملف:** `lib/features/dashboard/dashboard_page.dart`

```dart
ElevatedButton.icon(
  icon: Icon(Icons.mic),
  label: Text('Voice Assistant'),
  onPressed: widget.onVoice,  // ← هنا يبدأ كل شيء
)
```

**ينتقل إلى:** `lib/main.dart` - HomePage

```dart
void _navigateToVoiceAssistant() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => VoiceAssistantPage()),
  );
}
```

**النتيجة:** 
- ✅ تفتح صفحة Voice Assistant
- 🎨 تظهر الأنيميشن (Waveform + Pulse)

---

### 2️⃣ الضغط المستمر على زر التسجيل (Push-to-Talk)

**الملف:** `lib/features/voice_commands/presentation/voice_assistant_page.dart`

```dart
GestureDetector(
  onLongPressStart: (_) {
    // بداية التسجيل
    context.read<VoiceBloc>().add(StartListeningEvent());
  },
  onLongPressEnd: (_) {
    // نهاية التسجيل
    context.read<VoiceBloc>().add(StopListeningEvent());
  },
  child: // زر الميكروفون مع الأنيميشن
)
```

**ينتقل إلى:** `lib/features/voice_commands/presentation/blocs/voice_bloc.dart`

```dart
Future<void> _onStartListening(StartListeningEvent event, Emitter emit) async {
  emit(VoiceLoading());  // شاشة التحميل
  
  final result = await repository.startListening();
  
  result.fold(
    (failure) => emit(VoiceError(failure.toString())),
    (voiceResult) {
      emit(VoiceListening(voiceResult));
      // الاستماع للتحديثات المباشرة
      _subscription = repository.voiceStream.listen((result) {
        add(VoiceResultEvent(result));
      });
    },
  );
}
```

**ينتقل إلى:** `lib/features/voice_commands/data/datasources/voice_remote_data_source.dart`

```dart
Future<Either<Failure, VoiceResult>> startListening() async {
  try {
    await _ensureInitialized();  // التأكد من جاهزية speech_to_text
    
    await _speechToText.listen(
      onResult: (result) {
        final recognizedText = result.recognizedWords;
        _voiceController.add(VoiceResult(
          recognizedText: recognizedText,
          confidence: result.confidence,
          isFinal: result.finalResult,
        ));
      },
      localeId: 'ar_EG',  // اللغة العربية (أو en_US للإنجليزية)
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,  // عرض النتائج المؤقتة
    );
    
    return Right(VoiceResult(recognizedText: '', confidence: 0.0));
  } catch (e) {
    return Left(VoiceFailure('Failed to start listening: $e'));
  }
}
```

**النتيجة:**
- 🎤 الميكروفون يبدأ التسجيل
- 📝 النص يظهر مباشرة على الشاشة (live)
- 🌊 أنيميشن الموجات تتحرك

---

### 3️⃣ رفع اليد من الزرار (إيقاف التسجيل)

**الملف:** `voice_bloc.dart`

```dart
Future<void> _onStopListening(StopListeningEvent event, Emitter emit) async {
  _subscription?.cancel();  // إيقاف الاستماع للتحديثات
  
  emit(VoiceLoading());
  
  final result = await repository.stopListening();
  
  result.fold(
    (failure) => emit(VoiceError(failure.toString())),
    (voiceResult) async {
      // إذا لم يتم التعرف على نص، العودة للحالة الأولية
      if (voiceResult.recognizedText.isEmpty) {
        emit(VoiceInitial());
        return;
      }
      
      // معالجة الأمر الصوتي...
    },
  );
}
```

**ينتقل إلى:** `voice_remote_data_source.dart`

```dart
Future<Either<Failure, VoiceResult>> stopListening() async {
  try {
    await _speechToText.stop();
    
    final recognizedText = _lastRecognizedText;
    final confidence = _lastConfidence;
    
    return Right(VoiceResult(
      recognizedText: recognizedText,
      confidence: confidence,
      isFinal: true,
    ));
  } catch (e) {
    return Left(VoiceFailure('Failed to stop listening: $e'));
  }
}
```

**النتيجة:**
- 🛑 الميكروفون يتوقف
- 📋 النص النهائي: "شغل النور"
- ⏭️ الانتقال لمعالجة الأمر بالذكاء الاصطناعي

---

### 4️⃣ معالجة الأمر بالذكاء الاصطناعي (Gemini AI)

**الملف:** `voice_bloc.dart` - داخل `_onStopListening`

```dart
// جلب إعدادات المستخدم
final persona = settingsCubit.state.persona;  // مثال: Jarvis
final userName = settingsCubit.state.userName;  // مثال: Ahmed
final customName = settingsCubit.state.customPersonaName;

// بناء الـ prompt للذكاء الاصطناعي
final prompt = geminiService.buildPrompt(
  command: voiceResult.recognizedText,  // "شغل النور"
  persona: persona.name,                 // "Jarvis"
  language: persona.language,            // "ar"
  userName: userName,                    // "Ahmed"
  personaName: customName,
  gender: persona.gender,
  nationality: persona.nationality,
  personality: persona.personality,
);
```

**ينتقل إلى:** `lib/core/services/gemini_service.dart`

```dart
String buildPrompt({
  required String command,
  required String persona,
  required String language,
  String? userName,
  // ...
}) {
  return '''
You are Jarvis, a smart home AI assistant with advanced capabilities.

Persona Details:
- Name: Jarvis
- Gender: male
- Nationality: international
- Personality: professional
- Language: ar

User Context:
User's name is Ahmed.

SMART HOME DEVICES & ACTIONS:
🔵 LEDs:
- led1_on, led1_off: LED 1 (Living room light)
- led2_on, led2_off: LED 2 (Bedroom light)
- both_on, both_off: Both LEDs together
Synonyms: light, lamp, bulb, إضاءة, نور, لمبة

🚪 Door & Security:
- door_open: Open/unlock the door (servo 90°)
- door_close: Close/lock the door (servo 0°)
- door_toggle: Toggle door state
Synonyms: باب, door, gate, entrance, unlock, lock, افتح, قفل

🌀 Fan:
- fan_on: Turn on the fan
- fan_off: Turn off the fan
- fan_toggle: Toggle fan state
Synonyms: مروحة, ventilator, air, هواء, تهوية

🔔 Buzzer/Alarm:
- buzzer_on: Activate buzzer/alarm
- buzzer_off: Deactivate buzzer
- alert: Sound alert

🏠 Smart Scenes:
- home_mode: All lights on, door locked
- away_mode: All off, door locked, alarm on
- night_mode: Dim lights, door locked

❓ Status Queries:
- status_all: Report status of all devices
- what_is_on: Tell me what's currently on

ENHANCED UNDERSTANDING:
- Arabic colloquial: "شغل النور" = led1_on
- English casual: "lights out" = both_off
- Ambiguous: "turn everything on" = both_on + fan_on + door_open

Command: "شغل النور"

Response Format (STRICT JSON):
{
  "action": "led1_on",
  "confidence": 0-100,
  "response": "natural response in ar",
  "user_name": null,
  "language_switch": null,
  "parameters": {...}
}
''';
}
```

**إرسال الـ Prompt لـ Gemini API:**

```dart
Future<String> processPrompt(String prompt) async {
  try {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '{"action": "unknown", ...}';
  } catch (e) {
    return '{"action": "error", ...}';
  }
}
```

**رد Gemini AI:**

```json
{
  "action": "led1_on",
  "confidence": 95,
  "response": "حاضر يا أحمد، تم تشغيل إضاءة الصالة",
  "user_name": null,
  "language_switch": null,
  "parameters": {}
}
```

---

### 5️⃣ تحليل رد الذكاء الاصطناعي

**الملف:** `voice_bloc.dart`

```dart
final geminiResponse = await geminiService.processPrompt(prompt);

// تحليل الرد JSON
final parsed = _parseGeminiResponse(geminiResponse);

Map<String, dynamic> _parseGeminiResponse(String response) {
  try {
    // استخراج JSON من النص
    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}');
    final jsonString = response.substring(jsonStart, jsonEnd + 1);
    
    // استخراج القيم باستخدام RegEx
    final action = _extractAction(jsonString);      // "led1_on"
    final confidence = _extractConfidence(jsonString); // 95
    final resp = _extractResponse(jsonString);      // "حاضر يا أحمد..."
    
    return {
      'action': action,
      'confidence': confidence,
      'response': resp,
      'user_name': _extractUserName(jsonString),
      'language_switch': _extractLanguageSwitch(jsonString),
    };
  } catch (e) {
    return {
      'action': 'error',
      'confidence': 0,
      'response': 'Error parsing response: $e',
    };
  }
}
```

**النتيجة:**
```dart
parsed = {
  'action': 'led1_on',
  'confidence': 95,
  'response': 'حاضر يا أحمد، تم تشغيل إضاءة الصالة',
  'user_name': null,
  'language_switch': null,
}
```

---

### 6️⃣ تنفيذ الأمر في قاعدة البيانات

**الملف:** `voice_bloc.dart`

```dart
await _updateDeviceState(parsed['action'] as String);

Future<void> _updateDeviceState(String action) async {
  const deviceId = 'esp32s3-C54908';
  
  // جلب الحالة الحالية أولاً
  final currentState = await supabaseService.getDeviceState(deviceId);
  
  bool? led1, led2, fanOn, buzzerOn, doorLocked;
  int? servoAngle;
  
  // تحديد التغييرات بناءً على الـ action
  switch (action) {
    case 'led1_on':
      led1 = true;
      break;
    case 'led1_off':
      led1 = false;
      break;
    case 'both_on':
      led1 = true;
      led2 = true;
      break;
    case 'door_open':
      doorLocked = false;
      servoAngle = 90;  // زاوية الفتح
      break;
    case 'home_mode':
      led1 = true;
      led2 = true;
      doorLocked = true;
      fanOn = false;
      buzzerOn = false;
      servoAngle = 0;
      break;
    case 'away_mode':
      led1 = false;
      led2 = false;
      doorLocked = true;
      fanOn = false;
      buzzerOn = true;  // تفعيل الإنذار
      servoAngle = 0;
      break;
    // ... باقي الحالات
  }
  
  // تحديث قاعدة البيانات
  await supabaseService.updateDeviceState(
    deviceId,
    led1: led1,
    led2: led2,
    fanOn: fanOn,
    buzzerOn: buzzerOn,
    doorLocked: doorLocked,
    servoAngle: servoAngle,
  );
}
```

**ينتقل إلى:** `lib/core/services/supabase_service.dart`

```dart
Future<void> updateDeviceState(
  String deviceId, {
  bool? led1,
  bool? led2,
  bool? fanOn,
  bool? buzzerOn,
  bool? doorLocked,
  int? servoAngle,
}) async {
  try {
    print('🔄 SupabaseService: Updating device state for: $deviceId');
    
    // 1. جلب الحالة الحالية
    final currentState = await getDeviceState(deviceId);
    
    // 2. دمج القيم القديمة مع الجديدة
    final data = <String, dynamic>{
      'device_id': deviceId,
      'updated_at': DateTime.now().toIso8601String(),
      // الاحتفاظ بالقيم القديمة للأجهزة غير المحدثة
      'led1': led1 ?? currentState?['led1'] ?? false,
      'led2': led2 ?? currentState?['led2'] ?? false,
      'fan_on': fanOn ?? currentState?['fan_on'] ?? false,
      'buzzer_on': buzzerOn ?? currentState?['buzzer_on'] ?? false,
      'door_locked': doorLocked ?? currentState?['door_locked'] ?? true,
      'servo_angle': servoAngle ?? currentState?['servo_angle'] ?? 0,
    };
    
    print('📝 Data to insert (merged with current state): $data');
    
    // 3. إضافة صف جديد في الجدول
    final insertResponse = await _client
        .from('iot_control')
        .insert(data)
        .select();
    
    print('✅ New device state inserted with full state preserved');
  } catch (e, stackTrace) {
    print('❌ Failed to insert device state: $e');
    throw Exception('Failed to insert device state: $e');
  }
}
```

**النتيجة في قاعدة البيانات (Supabase):**

جدول `iot_control`:
```
| id | device_id      | led1 | led2 | fan_on | door_locked | servo_angle | updated_at          |
|----|----------------|------|------|--------|-------------|-------------|---------------------|
| 1  | esp32s3-C54908 | true | true | false  | true        | 0           | 2025-11-04 10:30:00 |
```

**ملاحظة مهمة:**
- ✅ كل صف يحتوي على **الحالة الكاملة** لجميع الأجهزة
- ✅ لا يتم مسح أو تعديل الصفوف القديمة (INSERT only)
- ✅ آخر صف = أحدث حالة للأجهزة

---

### 7️⃣ حفظ الأمر في سجل الأوامر

**الملف:** `voice_bloc.dart`

```dart
try {
  await supabaseService.saveCommand(
    voiceResult.recognizedText,        // "شغل النور"
    parsed['action'] as String,        // "led1_on"
    parsed['confidence'] as int,       // 95
    parsed['response'] as String,      // "حاضر يا أحمد..."
  );
} catch (e) {
  print('Failed to save command: $e');
}
```

**ينتقل إلى:** `supabase_service.dart`

```dart
Future<void> saveCommand(
  String command,
  String action,
  int confidence,
  String response,
) async {
  try {
    await _client.from('voice_commands').insert({
      'command': command,
      'action': action,
      'confidence': confidence,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    throw Exception('Failed to save command: $e');
  }
}
```

**النتيجة في قاعدة البيانات:**

جدول `voice_commands`:
```
| id | command    | action   | confidence | response                          | timestamp           |
|----|-----------|----------|------------|----------------------------------|---------------------|
| 1  | شغل النور | led1_on  | 95         | حاضر يا أحمد، تم تشغيل إضاءة...  | 2025-11-04 10:30:00 |
```

**الفائدة:**
- 📊 تتبع الأوامر الصوتية
- 🧠 تحليل سلوك المستخدم
- 🐛 تصحيح الأخطاء (debugging)

---

### 8️⃣ نطق الرد بصوت عالي (Text-to-Speech)

**الملف:** `voice_bloc.dart`

```dart
// ضبط اللغة حسب الـ persona
await ttsService.setLanguage(persona.language);  // "ar"

// نطق الرد
await ttsService.speak(parsed['response'] as String);
```

**ينتقل إلى:** `lib/core/services/text_to_speech_service.dart`

```dart
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);  // "ar-SA" للعربية
    
    // إعدادات إضافية
    await _flutterTts.setPitch(1.0);          // درجة الصوت
    await _flutterTts.setSpeechRate(0.5);     // سرعة الكلام
    await _flutterTts.setVolume(1.0);         // مستوى الصوت
  }
  
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
    print('🔊 Speaking: $text');
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
```

**النتيجة:**
- 🔊 يتم نطق: "حاضر يا أحمد، تم تشغيل إضاءة الصالة"
- 🗣️ بصوت عربي طبيعي
- ⚡ بسرعة 0.5 (واضح ومفهوم)

---

### 9️⃣ تحديث واجهة المستخدم (UI Update)

**الملف:** `voice_bloc.dart`

```dart
emit(VoiceSuccess(
  command: voiceResult.recognizedText,  // "شغل النور"
  action: parsed['action'] as String,   // "led1_on"
  confidence: parsed['confidence'] as int,  // 95
  response: parsed['response'] as String,   // "حاضر يا أحمد..."
));
```

**ينتقل إلى:** `dashboard_page.dart` - BlocListener

```dart
BlocListener<VoiceBloc, VoiceState>(
  listener: (context, state) => _handleVoiceStateChange(state),
)

void _handleVoiceStateChange(VoiceState state) {
  if (state is! VoiceSuccess) return;
  
  final action = state.action.toLowerCase();  // "led1_on"
  
  setState(() {
    _updateDevicesFromAction(action);
  });
  
  _loadDeviceState();  // تحديث من قاعدة البيانات
  _loadSensorData();   // تحديث بيانات السنسورات
}

void _updateDevicesFromAction(String action) {
  if (action.contains('led1')) {
    led1On = action.contains('on');  // true
  } else if (action.contains('led2')) {
    led2On = action.contains('on');
  } else if (action.contains('both')) {
    led1On = led2On = action.contains('on');
  } else if (action.contains('fan')) {
    fanOn = action.contains('on');
  } else if (action.contains('door')) {
    doorLocked = action.contains('close') || action.contains('lock');
  }
  // ... المزيد من الحالات
}
```

**النتيجة في الواجهة:**
- ✅ بطاقة LED 1 تتحول للون الأزرق
- ✅ السويتش يتحرك لوضع ON
- ✅ النص يتغير من "OFF" إلى "ON"
- 🎨 الأنيميشن Gradient يتحول

**الملف:** `dashboard_page.dart` - DeviceCard

```dart
DeviceCard(
  title: 'LED 1',
  subtitle: 'Living room',
  isOn: led1On,  // ← تحديث هنا
  deviceKey: 'led1',
  icon: Icons.lightbulb,
  onChanged: (val) => _handleDeviceToggle('led1', val),
)
```

---

### 🔟 المزامنة التلقائية المستمرة

**الملف:** `dashboard_page.dart`

```dart
class _DashboardPageState extends State<DashboardPage> {
  Timer? _syncTimer;
  
  @override
  void initState() {
    super.initState();
    _loadDeviceState();
    _loadSensorData();
    
    // مزامنة تلقائية كل ثانية
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadDeviceState();
      _loadSensorData();
    });
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();  // إيقاف Timer عند الخروج
    super.dispose();
  }
}

Future<void> _loadDeviceState() async {
  try {
    final supabaseService = context.read<SupabaseService>();
    final deviceState = await supabaseService.getDeviceState('esp32s3-C54908');
    
    if (deviceState != null && mounted) {
      setState(() {
        led1On = deviceState['led1'] ?? false;
        led2On = deviceState['led2'] ?? false;
        fanOn = deviceState['fan_on'] ?? false;
        doorLocked = deviceState['door_locked'] ?? true;
      });
      
      print('✅ Device state synced: LED1=$led1On, LED2=$led2On, ...');
    }
  } catch (e) {
    print('❌ Failed to load device state: $e');
  }
}
```

**الفائدة:**
- 🔄 كل ثانية يتم جلب أحدث حالة من قاعدة البيانات
- 📡 حتى لو ESP32 غير الحالة، الأزرار تتحدث تلقائياً
- 🔁 مزامنة بين عدة أجهزة (تطبيق على الموبايل + ESP32 + Web)

---

## ⏱️ Timeline الكامل

```
[0.0s]  👆 تضغط على زر Mic في Dashboard
[0.1s]  📱 تفتح صفحة VoiceAssistantPage
[0.2s]  👆 تضغط باستمرار على زر Record
[0.3s]  🎤 الميكروفون يبدأ التسجيل
[0.4s]  🌊 أنيميشن الموجات تبدأ
[1.0s]  🗣️ تقول: "شغل النور"
[1.2s]  📝 النص يظهر مباشرة على الشاشة
[1.5s]  👆 ترفع يدك من الزرار
[1.6s]  🛑 الميكروفون يتوقف
[1.7s]  📤 إرسال النص إلى Gemini AI
[1.8s]  ⏳ انتظار رد الـ AI
[2.0s]  🤖 Gemini يحلل: action = "led1_on"
[2.1s]  💾 تحديث قاعدة البيانات Supabase
[2.2s]  📝 حفظ الأمر في سجل voice_commands
[2.3s]  🔊 نطق الرد: "حاضر يا أحمد، تم تشغيل إضاءة الصالة"
[2.4s]  🎨 تحديث Dashboard - LED 1 يشتغل
[2.5s]  ✅ الـ UI يعكس الحالة الجديدة
[3.0s]  🔄 Timer يجلب آخر حالة من DB (مزامنة)
[4.0s]  🔄 مزامنة تلقائية مرة أخرى
[5.0s]  🔄 مزامنة تلقائية...
```

**إجمالي الوقت من الضغط حتى التنفيذ: ~2.5 ثانية** ⚡

---

## 🌟 الميزات الذكية

### 1. فهم اللهجة العامية والمترادفات

**أمثلة عربية:**
```
"شغل النور"        → led1_on
"افتح الإضاءة"      → led1_on
"ضوي اللمبة"       → led1_on
"طفي كل حاجة"      → both_off + fan_off
"قفل الباب"        → door_close
```

**أمثلة إنجليزية:**
```
"turn on the light"     → led1_on
"lights out"            → both_off
"open the door"         → door_open
"turn everything on"    → both_on + fan_on
```

### 2. التعامل مع التعليمات المركبة

```
"افتح الباب وشغل النور"
→ action: "door_open"
→ parameters: { devices: ["door", "led1", "led2"] }
→ ينفذ: door_open + led1_on + led2_on
```

### 3. الاستعلام عن الحالة

**الأمر:**
```
"ايه شغال؟" / "What's on?"
```

**الرد:**
```
حالة المنزل الآن:

🟢 الأجهزة المشغلة:
  • إضاءة الصالة
  • المروحة

⚫ الأجهزة المطفية:
  • إضاءة غرفة النوم

🚪 الباب مقفل
🌡️ الحرارة: 24.5°س
💧 الرطوبة: 60%
```

**التنفيذ:**
- ينتقل إلى `voice_bloc.dart` → `_generateStatusResponse()`
- يجلب الحالة من قاعدة البيانات
- يبني رد تفصيلي باللغة المناسبة

### 4. Smart Scenes (الوضعيات الذكية)

**Home Mode:**
```
"وضع المنزل" / "Home mode"
→ كل الأنوار ON
→ الباب Locked
→ المروحة OFF
→ الإنذار OFF
```

**Away Mode:**
```
"أنا طالع" / "I'm leaving"
→ كل الأنوار OFF
→ الباب Locked
→ المروحة OFF
→ الإنذار ON (buzzer)
```

**Night Mode:**
```
"وضع النوم" / "Night mode"
→ إضاءة الصالة OFF
→ إضاءة غرفة النوم ON
→ الباب Locked
→ المروحة ON
```

---

## 🗂️ بنية الملفات والمسؤوليات

### Presentation Layer (UI)

```
lib/features/voice_commands/presentation/
├── voice_assistant_page.dart
│   ├── 🎨 واجهة المستخدم
│   ├── 🎭 الأنيميشن (Waveform + Pulse)
│   └── 👆 معالجة الضغط (GestureDetector)
│
└── blocs/
    ├── voice_bloc.dart
    │   ├── 🧠 منطق التطبيق الأساسي
    │   ├── 🔄 تنسيق العمليات
    │   ├── 📊 إدارة الحالة (State Management)
    │   └── 🔀 الربط بين الطبقات
    │
    ├── voice_event.dart
    │   ├── StartListeningEvent
    │   ├── StopListeningEvent
    │   ├── VoiceResultEvent
    │   └── TextCommandEvent
    │
    └── voice_state.dart
        ├── VoiceInitial
        ├── VoiceLoading
        ├── VoiceListening
        ├── VoiceSuccess
        └── VoiceError
```

### Domain Layer (Business Logic)

```
lib/features/voice_commands/domain/
├── repositories/
│   └── voice_repository.dart
│       ├── 🔌 واجهة التطبيق (Interface)
│       └── 📜 العقد (Contract)
│
└── entities/
    └── voice_result.dart
        ├── recognizedText
        ├── confidence
        └── isFinal
```

### Data Layer (External Services)

```
lib/features/voice_commands/data/
├── repositories/
│   └── voice_repository_impl.dart
│       └── 🔧 تطبيق الواجهة
│
└── datasources/
    └── voice_remote_data_source.dart
        ├── 🎤 speech_to_text integration
        ├── 🔊 التحكم في الميكروفون
        └── 📡 Stream للنتائج المباشرة
```

### Core Services

```
lib/core/services/
├── gemini_service.dart
│   ├── 🤖 بناء الـ Prompts
│   ├── 📤 إرسال للـ AI
│   └── 📥 استقبال الردود
│
├── supabase_service.dart
│   ├── 💾 updateDeviceState()
│   ├── 📊 getDeviceState()
│   ├── 🌡️ getSensorData()
│   ├── 📝 saveCommand()
│   └── 🗺️ saveSystemInfo()
│
├── text_to_speech_service.dart
│   ├── 🔊 speak()
│   ├── 🌍 setLanguage()
│   └── ⏹️ stop()
│
└── device_info_service.dart
    ├── 📍 getCurrentLocation()
    ├── 🌤️ getWeatherInfo()
    └── ⏰ getCurrentDateTime()
```

---

## 🔐 قاعدة البيانات (Supabase)

### جدول: `iot_control`

```sql
CREATE TABLE iot_control (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  led1 BOOLEAN DEFAULT FALSE,
  led2 BOOLEAN DEFAULT FALSE,
  fan_on BOOLEAN DEFAULT FALSE,
  buzzer_on BOOLEAN DEFAULT FALSE,
  door_locked BOOLEAN DEFAULT TRUE,
  servo_angle INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**الاستخدام:**
- كل صف = حالة كاملة لجميع الأجهزة في لحظة معينة
- آخر صف = أحدث حالة
- INSERT only (لا يتم UPDATE أو DELETE)

### جدول: `voice_commands`

```sql
CREATE TABLE voice_commands (
  id BIGSERIAL PRIMARY KEY,
  command TEXT NOT NULL,
  action TEXT NOT NULL,
  confidence INTEGER,
  response TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**الاستخدام:**
- سجل جميع الأوامر الصوتية
- تحليل السلوك
- تصحيح الأخطاء

### جدول: `iot_data`

```sql
CREATE TABLE iot_data (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  temperature DOUBLE PRECISION,
  humidity DOUBLE PRECISION,
  distance DOUBLE PRECISION,
  motion BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**الاستخدام:**
- بيانات السنسورات من ESP32
- عرض في Dashboard

---

## 🎯 نقاط القوة في التصميم

### 1. Clean Architecture
- ✅ فصل واضح بين الطبقات (Presentation / Domain / Data)
- ✅ سهولة الاختبار (Testability)
- ✅ قابلية التوسع (Scalability)

### 2. State Management (BLoC)
- ✅ حالات واضحة (Loading, Success, Error)
- ✅ Reactive Programming
- ✅ سهولة تتبع التغييرات

### 3. Repository Pattern
- ✅ فصل منطق البيانات عن UI
- ✅ سهولة تبديل مصادر البيانات
- ✅ Testable

### 4. Dependency Injection
- ✅ استخدام Provider
- ✅ Loose Coupling
- ✅ سهولة الصيانة

### 5. Error Handling
- ✅ Either<Failure, Success>
- ✅ رسائل خطأ واضحة
- ✅ Graceful degradation

---

## 🚀 التحسينات المستقبلية الممكنة

### 1. Realtime Sync (WebSockets)
```dart
// بدلاً من Timer.periodic
final stream = supabase
  .from('iot_control')
  .stream(primaryKey: ['id'])
  .listen((data) {
    // تحديث فوري عند تغيير قاعدة البيانات
  });
```

### 2. Offline Support
```dart
// حفظ محلي + مزامنة لاحقة
await Hive.put('device_state', deviceState);
```

### 3. Multi-Language Models
```dart
// نماذج محلية للغات متعددة
if (language == 'ar') {
  model = 'gemini-2.5-flash-arabic';
} else {
  model = 'gemini-2.5-flash';
}
```

### 4. Voice Authentication
```dart
// التعرف على هوية المتحدث
final voiceprint = await voiceAuth.analyze(audioData);
if (voiceprint.user == 'Ahmed') {
  // السماح بالأوامر الحساسة
}
```

### 5. Context-Aware Commands
```dart
// فهم السياق
"شغله" → إذا كان آخر جهاز هو LED 1 → led1_on
"قفله" → إذا كان آخر جهاز هو الباب → door_close
```

---

## 📚 المراجع والمكتبات المستخدمة

### Packages

```yaml
dependencies:
  # UI & Framework
  flutter: sdk
  cupertino_icons: ^1.0.8
  
  # State Management
  flutter_bloc: ^8.1.6
  provider: ^6.1.2
  equatable: ^2.0.5
  
  # Voice
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  permission_handler: ^11.3.1
  
  # AI
  google_generative_ai: ^0.4.3
  
  # Backend
  supabase_flutter: ^2.5.8
  
  # System Info
  geolocator: ^12.0.0
  geocoding: ^3.0.0
  intl: ^0.19.0
  http: ^1.2.0
  
  # Utilities
  dartz: ^0.10.1
```

### APIs

- **Gemini AI**: `gemini-2.5-flash-native-audio-dialog`
- **Supabase**: PostgreSQL + Realtime
- **Open-Meteo**: Weather API (مجاني)
- **Geolocator**: GPS Services

---

## 🎓 خلاصة

رحلة الأمر الصوتي تمر بـ **10 مراحل** رئيسية:

1. 👆 الضغط على الميكروفون
2. 🎤 تسجيل الصوت (Push-to-Talk)
3. 🛑 إيقاف التسجيل
4. 🤖 معالجة بالذكاء الاصطناعي
5. 🧠 تحليل الرد
6. 💾 تنفيذ في قاعدة البيانات
7. 📝 حفظ في السجل
8. 🔊 نطق الرد
9. 🎨 تحديث الواجهة
10. 🔄 مزامنة مستمرة

**المدة الإجمالية: 2-3 ثواني فقط!** ⚡

---

**تاريخ آخر تحديث:** 4 نوفمبر 2025
**الإصدار:** 1.0.0
**المطور:** Smart Home Team
