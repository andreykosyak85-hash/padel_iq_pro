import 'package:flutter/material.dart';
import 'tournament_screen.dart'; 
import '../logic/rating_engine.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final double myRating = 3.300;

  // Список матчей
  List<Map<String, dynamic>> matches = [
    {
      'id': 1,
      'type': 'MATCH', 
      'title': 'Утренний спарринг',
      'time': '09:00',
      'court': 'Корт №3',
      'minRating': 1.0,
      'maxRating': 5.0,
      'playersCount': 3,
      'maxPlayers': 4,
      'price': '800₽',
      'isMyMatch': true, 
      'opponentRating': 2.5,
    },
  ];

  final List<String> gameFormats = ['MATCH', 'AMERICANO', 'MEXICANO', 'WINNER_COURT', 'TOURNAMENT'];

  // 🔥 1. ДОБАВЛЯЕМ ПРОПУЩЕННУЮ ФУНКЦИЮ ВЕСОВ
  double _getFormatWeight(String type) {
    switch (type) {
      case 'TOURNAMENT': return 1.2;
      case 'MATCH': return 1.0;
      case 'AMERICANO': return 0.85;
      case 'MEXICANO': return 0.75;
      case 'WINNER_COURT': return 0.8;
      default: return 1.0;
    }
  }

  // --- ЛОГИКА ---
  
  void _showCreateMatchDialog() {
    String title = 'Новая игра';
    String selectedFormat = 'MATCH'; 
    RangeValues currentRange = const RangeValues(1.0, 7.0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Создать игру'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Название'),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 15),
                    const Text('Формат игры:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedFormat,
                      isExpanded: true,
                      items: gameFormats.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => selectedFormat = newValue!);
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text('Уровень допуска:', style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: currentRange,
                      min: 1.0, max: 7.0, divisions: 12,
                      labels: RangeLabels(currentRange.start.toStringAsFixed(1), currentRange.end.toStringAsFixed(1)),
                      onChanged: (val) => setDialogState(() => currentRange = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      matches.add({
                        'id': matches.length + 1,
                        'type': selectedFormat,
                        'title': title,
                        'time': '20:00',
                        'court': 'Свой корт',
                        'minRating': currentRange.start,
                        'maxRating': currentRange.end,
                        'playersCount': 1,
                        'maxPlayers': (selectedFormat == 'MATCH' || selectedFormat == 'WINNER_COURT') ? 4 : 8,
                        'price': '1000₽',
                        'isMyMatch': true,
                        'opponentRating': 3.0,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleMatchAction(int index) {
    var match = matches[index];
    if (match['type'] != 'MATCH') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentScreen(
            title: match['title'],
            format: match['type'],
          ),
        ),
      );
      return;
    }
    _showMatchResultDialog(index);
  }

  void _showMatchResultDialog(int index) {
    TextEditingController s1t1 = TextEditingController(); TextEditingController s1t2 = TextEditingController();
    TextEditingController s2t1 = TextEditingController(); TextEditingController s2t2 = TextEditingController();
    TextEditingController s3t1 = TextEditingController(); TextEditingController s3t2 = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Результат матча 🎾'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите счет по сетам:'),
            const SizedBox(height: 10),
            _buildSetInput('Сет 1', s1t1, s1t2),
            _buildSetInput('Сет 2', s2t1, s2t2),
            _buildSetInput('Сет 3', s3t1, s3t2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _calculateRating(index, false); },
            child: const Text('Мы проиграли', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _calculateRating(index, true); },
            child: const Text('ПОБЕДА'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInput(String label, TextEditingController c1, TextEditingController c2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), 
          const SizedBox(width: 10),
          SizedBox(width: 50, child: TextField(controller: c1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
          SizedBox(width: 50, child: TextField(controller: c2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
        ],
      ),
    );
  }

  // 🔥 2. ОБНОВЛЕННЫЙ РАСЧЕТ С УЧЕТОМ ВЕСА ФОРМАТА
  void _calculateRating(int index, bool isWin) {
    var match = matches[index];
    
    // Получаем вес формата (MATCH=1.0, TOURNAMENT=1.2 и т.д.)
    double weight = _getFormatWeight(match['type']); 

    // Вызываем движок
    double delta = RatingEngine.calculateAdvancedDelta(
      currentRating: myRating,
      partnerRating: myRating, 
      opponentAvgRating: match['opponentRating'] ?? 3.0,
      gamesPlayed: 10,
      reliability: 1.0,
      stability: 1.0,
      repetitionCount: 0,
      groupTrust: 1.0,
      formatWeight: weight, // <--- СЮДА ПЕРЕДАЕМ ВЕС
      result: isWin ? 1 : 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isWin 
          ? 'Победа! Рейтинг: +${(delta).toStringAsFixed(3)} (Вес: x$weight)' 
          : 'Поражение... Рейтинг: ${(delta).toStringAsFixed(3)} (Вес: x$weight)'
        ),
        backgroundColor: isWin ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Игры и Турниры')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMatchDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          var match = matches[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: match['type'] == 'MATCH' ? Colors.blue : Colors.purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(match['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      Text(match['price'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(match['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(match['court']),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: match['isMyMatch'] ? () => _handleMatchAction(index) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: match['type'] == 'MATCH' ? Colors.green : Colors.deepPurple),
                      child: Text(
                        match['type'] == 'MATCH' ? 'Ввести результат' : 'Управление Турниром 🏆',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}