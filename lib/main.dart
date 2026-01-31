import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

// Импорты экранов (убедись, что файлы лежат в папке lib/screens/)
import 'screens/auth_screen.dart'; 
import 'screens/quiz_screen.dart'; 
import 'screens/home_screen.dart'; 
import 'screens/matches_screen.dart'; 
import 'screens/profile_screen.dart'; 
import 'screens/groups_screen.dart'; 

// ================================================================================
// © 2026 Andrii Kosiak - All Rights Reserved
// PADEL IQ PRO - Professional Padel Tennis Analysis Application
// Unauthorized copying, modification, or redistribution is strictly prohibited.
// ================================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase твоими ключами
  await Supabase.initialize(
    url: 'https://ktbjxkbazkcwhuilcwdr.supabase.co',
    anonKey: 'sb_publishable_7KiMaH9VWnjeiURtgke_zA_GqrotD0A',
  );

  runApp(const MyApp());
}

// Глобальный клиент для доступа из любой точки приложения
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Padel IQ Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Темный фон из твоих скринов
        primaryColor: const Color(0xFF007AFF),
      ),
      home: const AuthGate(), // Начинаем со шлюза проверки входа
    );
  }
}

// --------------------------------------------------------
// 🚪 ШЛЮЗ АВТОРИЗАЦИИ (БЕЗ БАГОВ)
// --------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        // Если SDK еще не проснулся
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFccff00))));
        }

        final session = authSnapshot.data?.session;

        // 1. Если НЕ вошел -> Экран Входа
        if (session == null) {
          return const AuthScreen();
        }

        // 2. Если вошел -> Ждем данные профиля
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('profiles')
              .stream(primaryKey: ['id'])
              .eq('id', session.user.id),
          builder: (context, profileSnapshot) {
            // Защита от "белого экрана": пока данных нет, крутим спиннер
            if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
              return const Scaffold(
                backgroundColor: Color(0xFF0D1117),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFccff00)),
                      SizedBox(height: 20),
                      Text("Синхронизация профиля...", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data!.first;
            final level = (profile['level'] as num?) ?? 0;

            // 3. Решаем: КВИЗ или ГЛАВНАЯ
            return level == 0 ? const QuizScreen() : const MainScaffold();
          },
        );
      },
    );
  }
}

// --------------------------------------------------------
// 📱 ГЛАВНЫЙ ЭКРАН С ВКЛАДКАМИ (BOTTOM NAVIGATION)
// --------------------------------------------------------
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  // Использование IndexedStack сохраняет состояние (скролл) каждой страницы
  final List<Widget> _pages = [
    const HomeScreen(),      
    const MatchesScreen(),   
    const Scaffold(backgroundColor: Color(0xFF0D1117), body: Center(child: Text("Бронь (Скоро)", style: TextStyle(color: Colors.white70)))),
    const GroupsScreen(),    
    const ProfileScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    // PopScope исправляет поведение кнопки "Назад" на Android
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0); // Возврат на главную вместо выхода
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, 
          backgroundColor: const Color(0xFF1C1C1E),
          selectedItemColor: const Color(0xFFccff00), // Твой лаймовый цвет акцентов
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true, 
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Главная"),
            BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: "Матчи"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Бронь"),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Группы"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}