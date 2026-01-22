import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'matches_screen.dart';

class DashboardScreen extends StatefulWidget {
  final double initialRating;
  const DashboardScreen({super.key, required this.initialRating});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Список страниц (без const, чтобы избежать ошибок)
    final List<Widget> pages = [
      MatchesScreen(),                 // 0: Главная
      BookingScreen(),                 // 1: Бронь
      ProfileScreen(rating: widget.initialRating), // 2: Профиль
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Padel MVP'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF10192B),
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_tennis),
            label: 'Матчи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Бронь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}