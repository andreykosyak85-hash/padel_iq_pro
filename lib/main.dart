import 'package:flutter/material.dart';
import 'package:padel_app/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'screens/auth_screen.dart'; // Твой экран входа
import 'screens/matches_screen.dart'; // Твой главный экран

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 ВСТАВЬ СЮДА СВОИ ДАННЫЕ ИЗ SUPABASE 👇
  await Supabase.initialize(
    url: 'https://ktbjxkbazkcwhuilcwdr.supabase.co', 
    anonKey: 'sb_publishable_7KiMaH9VWnjeiURtgke_zA_GqrotD0A',
  );

  runApp(const MyApp());
}

// Эта переменная даст нам доступ к базе из любой точки приложения
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        // Настроим цвета, чтобы везде было красиво
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2979FF),
          secondary: Colors.greenAccent,
        ),
      ),
      // МАГИЯ: Если юзер уже вошел - сразу показываем матчи.
      // Если нет - показываем экран входа.
      home: supabase.auth.currentSession != null 
          ? const MatchesScreen() 
          : const LoginScreen(),
    );
    // update version
  }
}