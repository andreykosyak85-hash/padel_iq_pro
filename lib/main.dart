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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.lime,
        ),
        useMaterial3: true,
      ), // <--- Вот эта запятая, скорее всего, потерялась!
      home: const LoginScreen(),
    );
  }
}

