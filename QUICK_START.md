# 🚀 دليل البدء السريع

## خطوات التشغيل السريعة

### 1️⃣ تثبيت المتطلبات

```bash
# تثبيت Flutter SDK (إذا لم يكن مثبتاً)
# قم بزيارة: https://flutter.dev/docs/get-started/install

# تحقق من التثبيت
flutter doctor
```

### 2️⃣ استنساخ المشروع

```bash
git clone <repository-url>
cd home_app
```

### 3️⃣ تثبيت الحزم

```bash
flutter pub get
```

### 4️⃣ إعداد API Keys

#### Gemini API Key
1. اذهب إلى: https://makersuite.google.com/app/apikey
2. أنشئ API key جديد
3. افتح ملف `lib/main.dart`
4. استبدل `YOUR_GEMINI_API_KEY` بالمفتاح الخاص بك:

```dart
geminiService = GeminiService(
  'ضع_مفتاح_Gemini_هنا',
);
```

#### Supabase Credentials
1. اذهب إلى: https://supabase.com
2. أنشئ مشروع جديد
3. افتح ملف `lib/main.dart`
4. استبدل الـ URL والـ ANON KEY:

```dart
await Supabase.initialize(
  url: 'ضع_Supabase_URL_هنا',
  anonKey: 'ضع_Supabase_ANON_KEY_هنا',
);
```

### 5️⃣ إعداد قاعدة البيانات

في Supabase SQL Editor، نفذ هذا الكود:

```sql
-- جدول التحكم في IoT
CREATE TABLE iot_control (
  id TEXT PRIMARY KEY,
  led1 BOOLEAN DEFAULT false,
  led2 BOOLEAN DEFAULT false,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- جدول الأوامر الصوتية
CREATE TABLE voice_commands (
  id SERIAL PRIMARY KEY,
  command TEXT NOT NULL,
  action TEXT,
  confidence INTEGER,
  response TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- إدراج صف افتراضي
INSERT INTO iot_control (id, led1, led2)
VALUES ('esp32s3-C54908', false, false);
```

### 6️⃣ تشغيل التطبيق

```bash
# على Android
flutter run

# على iOS (Mac فقط)
flutter run -d ios

# على Chrome (للتطوير)
flutter run -d chrome
```

## 🎯 اختبار سريع

بعد تشغيل التطبيق:

1. **الشاشة الترحيبية**: اضغط "Let's started"
2. **لوحة التحكم**: اضغط "Voice Assistant"
3. **المساعد الصوتي**: 
   - اضغط باستمرار على زر الميكروفون
   - قل: "مرحباً" أو "Hello"
   - اترك الزر
   - استمع للرد

### أوامر تجريبية

جرب هذه الأوامر:

**بالعربية:**
```
"مرحباً"
"ما اسمك؟"
"شغل الليد الأول"
"اطفي كل الليدات"
"شغل التكييف"
```

**بالإنجليزية:**
```
"Hello"
"What's your name?"
"Turn on LED 1"
"Turn off all lights"
"Turn on AC"
```

## ⚙️ تغيير الشخصية

1. من لوحة التحكم، اضغط على أيقونة الإعدادات (إن وجدت)
2. أو أضف زر للإعدادات في `dashboard_page.dart`
3. اختر من 5 شخصيات مختلفة:
   - **Emma** 🇬🇧 (إنجليزي)
   - **Layla** 🇪🇬 (عربي)
   - **Alex** 🇺🇸 (إنجليزي)
   - **Yuki** 🇯🇵 (إنجليزي)
   - **Omar** 🇸🇦 (عربي)

## 🐛 حل المشاكل الشائعة

### المشكلة: الميكروفون لا يعمل

**الحل:**
```bash
# على Android - تحقق من الأذونات في AndroidManifest.xml
# على iOS - تحقق من Info.plist
```

افتح التطبيق → الإعدادات → الأذونات → اسمح بالميكروفون

### المشكلة: خطأ في Gemini API

**الأسباب المحتملة:**
- API Key خاطئ
- انتهاء صلاحية المفتاح
- تجاوز الحد المجاني

**الحل:**
- تحقق من API Key
- أنشئ مفتاح جديد
- راجع console للأخطاء

### المشكلة: لا يحفظ في Supabase

**الحل:**
1. تحقق من URL و ANON KEY
2. تأكد من إنشاء الجداول
3. راجع Row Level Security Policies:

```sql
-- اسمح بكل العمليات (للتطوير فقط)
ALTER TABLE iot_control ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON iot_control FOR ALL USING (true);

ALTER TABLE voice_commands ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON voice_commands FOR ALL USING (true);
```

## 📱 التطوير

### Hot Reload
أثناء التطوير، استخدم:
- **r** - Hot reload
- **R** - Hot restart
- **q** - Quit

### إضافة ميزة جديدة

1. أنشئ feature في `lib/features/`
2. اتبع Clean Architecture
3. استخدم Bloc للـ state management
4. اختبر الميزة

### بناء للإصدار

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🎨 التخصيص

### تغيير الألوان الرئيسية

في `lib/features/voice_commands/presentation/voice_assistant_page.dart`:

```dart
// غير اللون الأساسي
Color(0xFF1A237E) // الأزرق الداكن الحالي

// إلى اللون المفضل لديك
Color(0xFFYourColor)
```

### إضافة شخصية جديدة

في `lib/features/settings/settings_bloc.dart`:

```dart
static final List<PersonaProfile> availablePersonas = [
  // ... الشخصيات الموجودة
  PersonaProfile(
    id: 'new_persona',
    name: 'الاسم',
    gender: 'الجنس',
    nationality: 'الجنسية',
    language: 'ar', // أو 'en'
    personality: 'الشخصية',
    description: 'الوصف',
  ),
];
```

## 📚 موارد إضافية

- [Flutter Documentation](https://flutter.dev/docs)
- [Gemini AI Documentation](https://ai.google.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Bloc Tutorial](https://bloclibrary.dev/#/gettingstarted)

## 💡 نصائح

1. **استخدم DevTools**: `flutter run --enable-devtools`
2. **راقب console**: لمتابعة الأخطاء والـ logs
3. **اختبر على جهاز حقيقي**: لتجربة الصوت بشكل أفضل
4. **احفظ عملك**: استخدم Git للـ version control

## 🆘 الدعم

إذا واجهت مشاكل:
1. راجع هذا الدليل
2. تحقق من console للأخطاء
3. راجع documentation الرسمي
4. افحص GitHub Issues

---

**ملاحظة**: هذا المشروع تعليمي. لا تشارك API keys الخاصة بك علناً!

حظاً سعيداً! 🚀
