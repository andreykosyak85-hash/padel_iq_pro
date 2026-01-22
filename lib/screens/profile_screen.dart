import 'package:flutter/material.dart';
import 'rating_simulation_screen.dart'; // <--- Импорт экрана симуляции

class ProfileScreen extends StatelessWidget {
  // 1. Готовим место для приема рейтинга
  final double rating;

  const ProfileScreen({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Аватарка
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // Имя
          const Text(
            'Мой Профиль',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          
          // Статус меняется в зависимости от рейтинга
          Text(
            _getPlayerStatus(rating), 
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Табличка со статистикой
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Игр', '5'),
                _buildStat('Рейтинг', rating.toStringAsFixed(2)),
                _buildStat('Винрейт', '50%'),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // --- КНОПКИ ---

          // 1. Кнопка Настройки
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            label: const Text('Настройки'),
          ),

          const SizedBox(height: 16), // Отступ

          // 2. НОВАЯ КНОПКА: Лаборатория Рейтинга 🧪
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Передаем текущий рейтинг в лабораторию
                  builder: (context) => RatingSimulationScreen(currentRating: rating),
                ),
              );
            },
            icon: const Icon(Icons.science, color: Colors.purple),
            label: const Text('Лаборатория Рейтинга'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: const BorderSide(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  // Функция, которая определяет крутость игрока
  String _getPlayerStatus(double rating) {
    if (rating < 2.5) return 'Начинающий (Rookie)';
    if (rating < 4.5) return 'Любитель (Amateur)';
    if (rating < 6.0) return 'Продвинутый (Advanced)';
    return 'Профессионал (Pro)';
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}