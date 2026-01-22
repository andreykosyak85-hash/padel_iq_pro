import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Фон берется из темы
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. ЛОГОТИП (Свечение + Картинка)
              Container(
                height: 150, // Чуть увеличил для картинки
                width: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2979FF).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                // 🔥 ВАЖНО: Замени 'assets/logo.png' на реальный путь к твоему файлу
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              
              const SizedBox(height: 50),

              // 2. ЗАГОЛОВОК
              const Text(
                'Padel MVP',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              
              // 3. ПОДЗАГОЛОВОК
              Text(
                'Твой путь к профессиональному\nрейтингу начинается здесь',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 60),

              // 4. КНОПКА ВХОДА
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(initialRating: 3.40),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, color: Colors.black),
                  label: const Text('Войти через Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                   Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(initialRating: 3.40),
                      ),
                    );
                },
                child: const Text('Я просто посмотреть', style: TextStyle(color: Color(0xFF2979FF), fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}