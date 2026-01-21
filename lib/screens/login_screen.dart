import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'dashboard_screen.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Логотип (Картинка)
              // Исправлено: убрали const и лишние запятые
              Image.asset(
                'assets/logo.png',
                height: 150, 
                width: 150,  
              ),
              const SizedBox(height: 40),

              // 2. Заголовок
              const Text(
                'Добро пожаловать\nв Padel MVP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Подзаголовок
              const Text(
                'Твой путь к профессиональному\nрейтингу начинается здесь',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              // 4. Кнопка входа
              ElevatedButton.icon(
                onPressed: () {
                  // Переход на Опрос
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizScreen()), 
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Войти через Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 5. Кнопка "Пропустить"
              TextButton(
                onPressed: () {
                   // Переход сразу в Дашборд с рейтингом 1.0
                   Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(initialRating: 1.0)
                    ),
                  );
                },
                child: const Text('Я просто посмотреть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}