import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PadelApp());
}

class PadelApp extends StatelessWidget {
  const PadelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel MVP',
      debugShowCheckedModeBanner: false,
      // 🔥 ГЛОБАЛЬНАЯ ТЕМА (DARK NEON)
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050B18), // Тот самый глубокий синий
        primaryColor: const Color(0xFF2979FF), // Неоновый синий
        
        // Стиль карточек
        cardColor: const Color(0xFF10192B),
        
        // Стиль кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF), // Синяя кнопка
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Круглые края
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        
        // Стиль текстовых полей (Input)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF10192B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),

        // Шрифт
        fontFamily: 'Roboto', // Или любой другой
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}