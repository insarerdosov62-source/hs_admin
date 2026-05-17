import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:honda_admin/firebase_options.dart';
import 'service_request_screen.dart';
import 'service_history_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Не забудь импорт сверху!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // Если ты юзал flutterfire configure, он создаст файл firebase_options.dart
    // Тогда просто пиши:
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honda Admin',
      // --- ВОТ ЭТИ НАСТРОЙКИ НУЖНЫ ДЛЯ КАЛЕНДАРЯ ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский
        Locale('en', 'US'), // Английский (на всякий случай)
      ],
      locale: const Locale('ru', 'RU'), // Принудительно ставим русский интерфейс
      // --------------------------------------------
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), // Сделал красным под стиль Honda
        useMaterial3: true,
      ),
      home: const ServiceRequestScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HONDA SERVICE — Панель администратора",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFCC0000),
        // ВОТ ЭТОТ БЛОК НУЖЕН:
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 20),
              label: const Text("ИСТОРИЯ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFCC0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
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
      ),
    );
  }
}
