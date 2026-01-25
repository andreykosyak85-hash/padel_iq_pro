import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Импорты твоих экранов
import 'screens/login_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/home_screen.dart';     // 👈 Новый экран (Карточка)
import 'screens/profile_screen.dart';  // 👈 Экран профиля (Настройки)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 ТВОИ ДАННЫЕ SUPABASE
  await Supabase.initialize(
    url: 'https://ktbjxkbazkcwhuilcwdr.supabase.co',
    anonKey: 'sb_publishable_7KiMaH9VWnjeiURtgke_zA_GqrotD0A', // Твой ключ (я скрыл часть для безопасности, если копируешь - убедись что он полный)
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel IQ Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        // Цветовая схема приложения
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2979FF),
          secondary: Colors.greenAccent,
          surface: Color(0xFF1E293B), // Цвет для нижнего меню
        ),
      ),
      // 👇 ЛОГИКА: Если вошел -> Главное меню (MainNavigationScreen), иначе -> Вход
      home: supabase.auth.currentSession != null 
          ? const MainNavigationScreen() 
          : const LoginScreen(),
    );
  }
}

// 👇 НОВЫЙ КЛАСС: Управляет нижним меню
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Список экранов для переключения
  final List<Widget> _screens = [
    const HomeScreen(),      // 0: Главная (Твоя карточка)
    const MatchesScreen(),   // 1: Матчи (Список игр)
    const ProfileScreen(),   // 2: Профиль (Редактор)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Показываем текущий выбранный экран
      body: _screens[_currentIndex],
      
      // Нижняя панель навигации
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1))
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A), // Темный фон меню
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFFF2C94C), // Золотой цвет активной кнопки
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false, // Скрываем подписи неактивных кнопок для стиля
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_tennis),
              label: 'Матчи',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}