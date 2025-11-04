import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'core/services/gemini_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/text_to_speech_service.dart';
import 'core/services/user_cache_service.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/settings/settings_bloc.dart';
import 'features/voice_commands/data/datasources/voice_remote_data_source.dart';
import 'features/voice_commands/data/repositories/voice_repository_impl.dart';
import 'features/voice_commands/presentation/blocs/voice_bloc.dart';
import 'features/welcome/welcome_page.dart';
import 'features/voice_commands/presentation/voice_assistant_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.microphone.request();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tuyvnjyofajxaebfdfux.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1eXZuanlvZmFqeGFlYmZkZnV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDMwMzksImV4cCI6MjA3NzY3OTAzOX0.tMwpyj6XjLmASUQJGrXninVzUc235Ff98u9r22jVHAA',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GeminiService geminiService;
  late final SupabaseService supabaseService;
  late final TextToSpeechService ttsService;
  late final UserCacheService userCacheService;
  late final SettingsCubit settingsCubit;

  @override
  void initState() {
    super.initState();
    geminiService = GeminiService(
      'AIzaSyCZNXwSfvieBXEfb8T4JfwkwWosDTxNb8w',
    ); // Replace with your Gemini API key
    supabaseService = SupabaseService(
      'https://tuyvnjyofajxaebfdfux.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1eXZuanlvZmFqeGFlYmZkZnV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDMwMzksImV4cCI6MjA3NzY3OTAzOX0.tMwpyj6XjLmASUQJGrXninVzUc235Ff98u9r22jVHAA',
    ); // Replace with your Supabase credentials
    ttsService = TextToSpeechService();
    userCacheService = UserCacheService();
    settingsCubit = SettingsCubit();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsCubit),
        BlocProvider(
          create: (context) => VoiceBloc(
            VoiceRepositoryImpl(VoiceRemoteDataSourceImpl(SpeechToText())),
            geminiService,
            supabaseService,
            ttsService,
            userCacheService,
            settingsCubit,
          ),
        ),
        // Add SupabaseService as a Provider
        Provider<SupabaseService>.value(value: supabaseService),
      ],
      child: MaterialApp(
        title: 'Home App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MainHomePage(),
      ),
    );
  }
}

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Check if first time user, go directly to voice assistant for onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsCubit = context.read<SettingsCubit>();
      if (settingsCubit.state.isFirstTime) {
        setState(() => _page = 2); // Go to VoiceAssistantPage
      }
    });
  }

  void _goToDashboard() => setState(() => _page = 1);
  void _goToVoice() => setState(() => _page = 2);
  void _goBack() => setState(() => _page = 1);

  @override
  Widget build(BuildContext context) {
    if (_page == 0) {
      return WelcomePage(onStart: _goToDashboard);
    } else if (_page == 1) {
      return DashboardPage(onVoice: _goToVoice);
    } else {
      return VoiceAssistantPage(onBack: _goBack);
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
