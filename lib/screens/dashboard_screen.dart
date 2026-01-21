import 'package:flutter/material.dart';
import 'profile_screen.dart'; 
import 'matches_screen.dart';

class DashboardScreen extends StatefulWidget {
  // 1. Создаем "окошко" для приема рейтинга
  final double initialRating; 
  
  // Требуем рейтинг при открытии экрана (по умолчанию 1.0)
  const DashboardScreen({super.key, required this.initialRating});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Список страниц (теперь мы передаем рейтинг внутрь HomeContent)
    final List<Widget> pages = <Widget>[
      HomeContent(rating: widget.initialRating), // 0: Главная
      const MatchesScreen(),                     // 1: Матчи
      ProfileScreen(rating: widget.initialRating), // 2: Профиль (Исправлено!)
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Padel MVP'),
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Матчи'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  // Сюда тоже добавляем приемник переменной
  final double rating;
  const HomeContent({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                const Text('Твой Уровень', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                
                // 2. ВОТ ЗДЕСЬ ТЕПЕРЬ ЖИВАЯ ЦИФРА
                Text(
                  rating.toStringAsFixed(2), // Превращаем число (3.54321) в текст "3.54"
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)
                ),
                
                const SizedBox(height: 10),
                const Text('Калибровка: осталось 5 игр', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text('Ближайшие матчи', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // ... (дальше код карточки матча, можно оставить как было или я сократил для удобства)
        ],
      ),
    );
  }
}