import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Доступ к supabase

class TournamentScreen extends StatefulWidget {
  final String title;
  final String matchId;
  final int courts;
  final String gameType; // 'Americano (Ind)', 'Americano (Team)', 'Winner Court' и т.д.

  const TournamentScreen({
    super.key, 
    required this.title, 
    required this.matchId, 
    required this.courts,
    required this.gameType, 
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> with SingleTickerProviderStateMixin {
  int round = 1;
  List<Map<String, dynamic>> currentMatches = [];
  Map<String, int> scores = {}; // Очки игроков
  List<String> playersNames = [];
  
  // Для командных режимов храним фиксированные пары
  List<List<String>> fixedTeams = []; 

  bool isLoading = true;
  bool isTournamentFinished = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayersAndStart();
  }

  Future<void> _loadPlayersAndStart() async {
    try {
      final response = await supabase
          .from('participants')
          .select('user_id, profiles(username, email)')
          .eq('match_id', widget.matchId)
          .eq('status', 'CONFIRMED');

      List<String> loadedNames = [];
      
      for (var record in response) {
        final profile = record['profiles'];
        String name = profile['username'] ?? (profile['email'] as String).split('@')[0];
        loadedNames.add(name);
        scores[name] = 0;
      }

      setState(() {
        playersNames = loadedNames;
        isLoading = false;
      });

      // Добор ботов (чтобы кратно 4)
      int requiredPlayers = widget.courts * 4;
      if (playersNames.length < requiredPlayers) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Добавлено ${requiredPlayers - playersNames.length} ботов.")));
        while (playersNames.length < requiredPlayers) {
          String botName = "Бот ${playersNames.length + 1}";
          playersNames.add(botName);
          scores[botName] = 0;
        }
      }

      // Если режим Командный — формируем пары сразу
      if (widget.gameType.contains('Team') || widget.gameType.contains('Mixed')) {
        _createFixedTeams();
      }

      _generateRound();
    } catch (e) {
      debugPrint("Ошибка: $e");
      setState(() => isLoading = false);
    }
  }

  // Создание фиксированных команд (1+2, 3+4...)
  void _createFixedTeams() {
    fixedTeams.clear();
    List<String> pool = List.from(playersNames);
    // Можно добавить логику рандома или по рейтингу, пока просто по порядку
    for (int i = 0; i < pool.length; i += 2) {
      if (i + 1 < pool.length) {
        fixedTeams.add([pool[i], pool[i + 1]]);
      }
    }
  }

  // 🔥 МОЗГ ТУРНИРА: РАСПРЕДЕЛЕНИЕ 🔥
  void _generateRound() {
    if (isTournamentFinished) return;

    setState(() {
      currentMatches.clear();
      
      // --- ЛОГИКА 1: КОМАНДНЫЕ РЕЖИМЫ (Americano Team, Mexicano Team) ---
      if (widget.gameType.contains('Team') || widget.gameType.contains('Mixed')) {
        List<List<String>> teamsPool = List.from(fixedTeams);
        
        if (widget.gameType.contains('Mexicano')) {
          // Мексикано Командное: Сортируем команды по сумме очков
          teamsPool.sort((a, b) {
            int scoreA = scores[a[0]]! + scores[a[1]]!;
            int scoreB = scores[b[0]]! + scores[b[1]]!;
            return scoreB.compareTo(scoreA);
          });
        } else {
          // Американо Командное: Рандом
          teamsPool.shuffle();
        }

        // Создаем матчи Команда на Команду
        int matchesCount = (teamsPool.length / 2).floor();
        if (matchesCount > widget.courts) matchesCount = widget.courts;

        for (int i = 0; i < matchesCount; i++) {
          currentMatches.add({
            'court': i + 1,
            'team1': teamsPool[i * 2],     // Команда А
            'team2': teamsPool[i * 2 + 1], // Команда Б
            'score1': 0,
            'score2': 0,
          });
        }
      } 
      
      // --- ЛОГИКА 2: ИНДИВИДУАЛЬНЫЕ РЕЖИМЫ ---
      else {
        List<String> pool = List.from(playersNames);

        // A. Winner Court (Винер Корт) и Mexicano (Мексикано)
        // Сортируем игроков по очкам: Лучшие играют на 1 корте
        if (widget.gameType.contains('Mexicano') || widget.gameType.contains('Winner')) {
          pool.sort((a, b) => scores[b]!.compareTo(scores[a]!));
        } 
        // B. Americano (Классика) - полный рандом
        else {
          pool.shuffle();
        }

        // Распределение по кортам (по 4 человека)
        int matchesCount = (pool.length / 4).floor();
        if (matchesCount > widget.courts) matchesCount = widget.courts;

        for (int i = 0; i < matchesCount; i++) {
          // Берем четверку игроков
          List<String> p = [pool[i*4], pool[i*4+1], pool[i*4+2], pool[i*4+3]];
          
          List<String> t1, t2;

          // Внутри корта пары формируются:
          if (widget.gameType.contains('Mexicano')) {
             // 1+4 vs 2+3 (Уравнивание сил)
             t1 = [p[0], p[3]];
             t2 = [p[1], p[2]];
          } else {
             // Рандом/Winner: 1+2 vs 3+4
             t1 = [p[0], p[1]];
             t2 = [p[2], p[3]];
          }

          currentMatches.add({
            'court': i + 1,
            'team1': t1,
            'team2': t2,
            'score1': 0,
            'score2': 0,
          });
        }
      }
    });
  }

  // ЗАВЕРШЕНИЕ РАУНДА
  void _finishRound() {
    for (var match in currentMatches) {
      int s1 = match['score1'];
      int s2 = match['score2'];
      
      // Начисляем очки ВСЕМ участникам команды
      for (var p in match['team1']) {
        scores[p] = (scores[p] ?? 0) + s1;
      }
      for (var p in match['team2']) {
        scores[p] = (scores[p] ?? 0) + s2;
      }
      
      // Если "Super Mexicano" - бонус за победу на высоком корте (опционально)
      if (widget.gameType.contains('Super')) {
         int courtBonus = (widget.courts - (match['court'] as int) + 1) * 2; // Чем выше корт (1), тем больше бонус
         if (s1 > s2) for (var p in match['team1']) {
           scores[p] = scores[p]! + courtBonus;
         }
         if (s2 > s1) for (var p in match['team2']) {
           scores[p] = scores[p]! + courtBonus;
         }
      }
    }

    setState(() => round++);
    _generateRound();
    _tabController.animateTo(1); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Раунд $round! Пары обновлены.")));
  }

  void _finishTournamentEarly() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Завершить игру?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() { isTournamentFinished = true; });
              Navigator.pop(context);
              _tabController.animateTo(1); 
            }, 
            child: const Text("Завершить", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFF0D1117), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text("${widget.gameType} • Раунд $round", style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isTournamentFinished) 
            IconButton(icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent), onPressed: _finishTournamentEarly)
        ],
        bottom: TabBar(
          controller: _tabController, 
          indicatorColor: const Color(0xFF2F80ED),
          labelColor: const Color(0xFF2F80ED),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "Игры"), Tab(text: "Таблица")]
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ЭКРАН МАТЧЕЙ (ВВОД СЧЕТА)
          isTournamentFinished 
            ? Center(child: ElevatedButton(onPressed: () => _tabController.animateTo(1), child: const Text("Смотреть результаты")))
            : ListView(padding: const EdgeInsets.all(16), children: [
                ...currentMatches.map((m) => _buildMatchCard(m)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _finishRound, 
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                    child: const Text("Завершить раунд", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                  ),
                )
              ]),
          
          // ЭКРАН ТАБЛИЦЫ
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1))),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("КОРТ ${match['court']}", style: const TextStyle(color: Color(0xFF2F80ED), fontWeight: FontWeight.bold)),
        ]),
        const Divider(color: Colors.white24),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // Команда 1
          Expanded(child: Column(children: [for (var p in match['team1']) Text(p, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)])),
          
          // Счет
          Row(children: [
            _input(match, 'score1'), 
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text(":", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))), 
            _input(match, 'score2')
          ]),
          
          // Команда 2
          Expanded(child: Column(children: [for (var p in match['team2']) Text(p, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)])),
        ])
      ])),
    );
  }

  Widget _input(Map m, String k) => Container(
    width: 60, height: 50,
    decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
    child: Center(
      child: TextField(
        key: ValueKey("R${round}_${m['court']}_$k"),
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), 
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (v) => m[k] = int.tryParse(v) ?? 0,
      ),
    ),
  );

  Widget _buildLeaderboard() {
    var sorted = scores.keys.toList()..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length, 
      itemBuilder: (c, i) {
        String name = sorted[i];
        int score = scores[name]!;
        Color rankColor = i == 0 ? Colors.yellow : (i == 1 ? Colors.grey : (i == 2 ? Colors.orangeAccent : Colors.white));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Text("#${i + 1}", style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Text("$score", style: const TextStyle(color: Color(0xFF2F80ED), fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }
}