import 'package:flutter/material.dart';

// 1. Меняем на StatefulWidget, чтобы экран мог перерисовываться
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // ЭТО НАША БАЗА ДАННЫХ (Пока в памяти телефона)
  // Мы храним состояние каждого матча здесь
  List<Map<String, dynamic>> matches = [
    {
      'id': 1,
      'time': '18:00',
      'court': 'Корт №3 (Стекло)',
      'level': '1.0 - 2.5',
      'playersCount': 3,
      'maxPlayers': 4,
      'price': '800₽',
      'isMyMatch': false, // Я еще не записан
      'isOpen': true,     // Места есть
      'matchDate': DateTime.now().add(const Duration(hours: 24)), // Завтра
    },
    {
      'id': 2,
      'time': '19:30',
      'court': 'Корт №1 (Панорама)',
      'level': '3.0 - 4.5',
      'playersCount': 4,
      'maxPlayers': 4,
      'price': '1200₽',
      'isMyMatch': false,
      'isOpen': false,    // Мест нет
      'matchDate': DateTime.now().add(const Duration(hours: 24)),
    },
    {
      'id': 3,
      'time': '21:00',
      'court': 'Корт №2',
      'level': 'Любой уровень',
      'playersCount': 4, // Полная
      'maxPlayers': 4,
      'price': '600₽',
      'isMyMatch': true, // Это УЖЕ моя игра
      'isOpen': false,
      // Дата для проверки отмены (через 4 часа)
      'matchDate': DateTime.now().add(const Duration(hours: 4)), 
    },
  ];

  // ФУНКЦИЯ: Записаться на матч
  void _joinMatch(int index) {
    setState(() {
      // 1. Увеличиваем счетчик игроков
      matches[index]['playersCount']++;
      
      // 2. Помечаем, что это ТЕПЕРЬ МОЯ игра
      matches[index]['isMyMatch'] = true;

      // 3. Если стало 4/4, закрываем запись
      if (matches[index]['playersCount'] >= matches[index]['maxPlayers']) {
        matches[index]['isOpen'] = false;
      }
    });

    // Показываем сообщение об успехе
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ура! Вы записаны на матч! 🎾'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ФУНКЦИЯ: Лист ожидания
  void _joinWaitlist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Вы в листе ожидания! Мы сообщим, если место освободится.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ФУНКЦИЯ: Отмена (с проверкой времени)
  void _cancelMatch(int index, DateTime? matchDate) {
    if (matchDate != null) {
       final difference = matchDate.difference(DateTime.now()).inHours;
       if (difference < 5) {
         _showErrorDialog('До игры меньше 5 часов. Отмена только через админа.');
         return;
       }
    }

    // Если всё ок, отменяем
    setState(() {
      matches[index]['playersCount']--;
      matches[index]['isMyMatch'] = false;
      matches[index]['isOpen'] = true; // Снова открываем запись
    });

    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Бронь отменена.'))
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ок'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Расписание игр', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // ГЕНЕРИРУЕМ КАРТОЧКИ ИЗ НАШЕГО СПИСКА matches
          ...List.generate(matches.length, (index) {
            final match = matches[index];
            return _buildMatchCard(match, index);
          }),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, int index) {
    bool isFull = match['playersCount'] >= match['maxPlayers'];
    bool isMyMatch = match['isMyMatch'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Верхняя часть (Время, Корт, Цена)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(match['time'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(match['court'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Уровень: ${match['level']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ]),
              ]),
              Text(match['price'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Прогресс бар
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(
              value: match['playersCount'] / match['maxPlayers'],
              backgroundColor: Colors.grey[200],
              color: isFull ? Colors.orange : Colors.green,
              minHeight: 6,
            ))),
            const SizedBox(width: 10),
            Text('${match['playersCount']}/${match['maxPlayers']}', style: const TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 16),

          // --- УМНАЯ КНОПКА (ГЛАВНАЯ ЛОГИКА) ---
          SizedBox(
            width: double.infinity,
            child: isMyMatch
                ? OutlinedButton( // Если я записан -> Кнопка Отмены
                    onPressed: () => _cancelMatch(index, match['matchDate']),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Отменить участие'),
                  )
                : isFull // Если не я, но мест нет -> Лист ожидания
                    ? ElevatedButton(
                        onPressed: () => _joinWaitlist(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        child: const Text('В лист ожидания 🔔'),
                      )
                    : ElevatedButton( // Если места есть -> Записаться
                        onPressed: () => _joinMatch(index), // <--- ВОТ ЗДЕСЬ ВЫЗЫВАЕМ ЗАПИСЬ
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text('Записаться'),
                      ),
          ),
        ],
      ),
    );
  }
}