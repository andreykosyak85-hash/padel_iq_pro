import 'package:flutter/material.dart';

class TournamentScreen extends StatefulWidget {
  final String title;
  final String format; // 'AMERICANO', 'MEXICANO', 'WINNER_COURT'

  const TournamentScreen({super.key, required this.title, required this.format});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  // 1. СПИСОК ИГРОКОВ (Поле isMe=true означает, что это ты)
  List<Map<String, dynamic>> players = [
    {'name': 'Я (Вы)', 'points': 0, 'matches': 0, 'isMe': true}, 
    {'name': 'Сергей', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Иван', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Петр', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Дима', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Алекс', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Макс', 'points': 0, 'matches': 0, 'isMe': false},
    {'name': 'Олег', 'points': 0, 'matches': 0, 'isMe': false},
  ];

  List<Map<String, dynamic>> currentRoundMatches = [];
  int roundNumber = 0;

  @override
  void initState() {
    super.initState();
    _generateNextRound();
  }

  // ⚖️ ГЛАВНАЯ ФИШКА: ВЕСА ФОРМАТОВ
  double _getFormatWeight(String type) {
    switch (type) {
      case 'TOURNAMENT': return 1.2;   // Серьезный турнир
      case 'MATCH': return 1.0;        // Обычная игра
      case 'AMERICANO': return 0.85;   // Классика
      case 'WINNER_COURT': return 0.8; // Динамично
      case 'MEXICANO': return 0.75;    // Фаново/Рандомно
      default: return 1.0;
    }
  }

  // --- ЛОГИКА ИГРЫ ---

  void _generateNextRound() {
    setState(() {
      roundNumber++;
      currentRoundMatches.clear();
      
      // Простая генерация пар (для MVP - Random Shuffle)
      // В полной версии здесь будет логика Mexicano (лидеры с лидерами)
      var availablePlayers = List.of(players)..shuffle();
      
      while (availablePlayers.length >= 4) {
        currentRoundMatches.add({
          'court': 'Корт ${currentRoundMatches.length + 1}',
          't1p1': availablePlayers.removeAt(0),
          't1p2': availablePlayers.removeAt(0),
          't2p1': availablePlayers.removeAt(0),
          't2p2': availablePlayers.removeAt(0),
          'score1': 0,
          'score2': 0,
          'isFinished': false,
        });
      }
    });
  }

  void _submitScore(int matchIndex, int score1, int score2) {
    setState(() {
      var match = currentRoundMatches[matchIndex];
      match['score1'] = score1;
      match['score2'] = score2;
      match['isFinished'] = true;

      _addPoints(match['t1p1'], score1);
      _addPoints(match['t1p2'], score1);
      _addPoints(match['t2p1'], score2);
      _addPoints(match['t2p2'], score2);
    });
  }

  void _addPoints(Map<String, dynamic> playerRef, int points) {
    var p = players.firstWhere((element) => element['name'] == playerRef['name']);
    p['points'] = (p['points'] as int) + points;
    p['matches'] = (p['matches'] as int) + 1;
  }

  // 🔥 ЗАВЕРШЕНИЕ ТУРНИРА И РАСЧЕТ РЕЙТИНГА
  void _finishTournament() {
    // 1. Считаем статистику
    double totalPoints = 0;
    int totalPlayers = players.length;
    var myPlayer = players.firstWhere((p) => p['isMe'] == true);
    
    // Сортировка таблицы
    players.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    int myRank = players.indexOf(myPlayer) + 1;

    for (var p in players) {
      totalPoints += p['points'] as int;
    }
    double averagePoints = totalPoints / totalPlayers; 
    double myPoints = (myPlayer['points'] as int).toDouble();

    // 2. Расчет разницы (Ты против среднего)
    double diff = myPoints - averagePoints; 
    
    // 3. ПРИМЕНЯЕМ ВЕС ФОРМАТА ⚖️
    double formatK = _getFormatWeight(widget.format);
    
    // Формула: (Разница * Вес) / 1000
    double ratingDelta = (diff * formatK) / 1000.0; 

    // Лимиты (чтобы рейтинг не сломался от одной игры)
    if (ratingDelta > 0.15) ratingDelta = 0.15;
    if (ratingDelta < -0.15) ratingDelta = -0.15;

    // 4. Показываем результат
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('🏁 ${widget.format} завершен!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Место: #$myRank', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Ваши очки: ${myPoints.toInt()}'),
            Text('Среднее: ${averagePoints.toStringAsFixed(1)}'),
            const SizedBox(height: 10),
            
            // Показываем, какой вес сработал
            Row(
              children: [
                const Text('Вес формата: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)),
                  child: Text('x$formatK', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ],
            ),
            
            const Divider(),
            const Text('Итог рейтинга:', style: TextStyle(color: Colors.grey)),
            Text(
              ratingDelta > 0 ? '+${ratingDelta.toStringAsFixed(3)} 📈' : '${ratingDelta.toStringAsFixed(3)} 📉',
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold,
                color: ratingDelta >= 0 ? Colors.green : Colors.red
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: const Text('Принять'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var leaderboard = List.of(players);
    leaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.format),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _finishTournament,
              icon: const Icon(Icons.flag, color: Colors.red),
              label: const Text('Финиш', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // ЛИДЕРБОРД
          Container(
            height: 110,
            color: Colors.blueGrey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                var p = leaderboard[index];
                bool isMe = p['isMe'];
                return Container(
                  width: 85,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.yellow[700] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isMe ? Border.all(color: Colors.orange, width: 3) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(p['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      Text('${p['points']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                );
              },
            ),
          ),

          // УПРАВЛЕНИЕ РАУНДАМИ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Раунд #$roundNumber', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: currentRoundMatches.every((m) => m['isFinished']) ? _generateNextRound : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('След. круг'),
                )
              ],
            ),
          ),

          // СПИСОК МАТЧЕЙ
          Expanded(
            child: ListView.builder(
              itemCount: currentRoundMatches.length,
              itemBuilder: (context, index) {
                var match = currentRoundMatches[index];
                TextEditingController c1 = TextEditingController();
                TextEditingController c2 = TextEditingController();

                if (match['isFinished']) {
                  return Card(
                    color: Colors.green[50],
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      dense: true,
                      title: Text('${match['t1p1']['name']}/${match['t1p2']['name']} vs ${match['t2p1']['name']}/${match['t2p2']['name']}'),
                      trailing: Text('${match['score1']} - ${match['score2']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                }

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(match['court'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Column(children: [Text(match['t1p1']['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(match['t1p2']['name'], style: const TextStyle(fontWeight: FontWeight.bold))])),
                            Row(
                              children: [
                                SizedBox(width: 40, child: TextField(controller: c1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text('-')),
                                SizedBox(width: 40, child: TextField(controller: c2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
                              ],
                            ),
                            Expanded(child: Column(children: [Text(match['t2p1']['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(match['t2p2']['name'], style: const TextStyle(fontWeight: FontWeight.bold))])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                               if (c1.text.isNotEmpty && c2.text.isNotEmpty) {
                                 _submitScore(index, int.parse(c1.text), int.parse(c2.text));
                               }
                            },
                            child: const Text('OK'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}