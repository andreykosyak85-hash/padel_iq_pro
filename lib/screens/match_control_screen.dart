import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Для работы таймера
import '../main.dart'; // Для доступа к supabase

class MatchControlScreen extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchControlScreen({super.key, required this.match});

  @override
  State<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends State<MatchControlScreen> {
  // Таймер матча
  Timer? _timer;
  Duration _duration = Duration.zero;
  late DateTime _matchStartTime;
  
  // Таймер раундов/сетов
  Timer? _roundTimer;
  Duration _roundDuration = Duration.zero;
  bool _roundTimerActive = false;
  
  // Счет (Простой вариант для MVP)
  int scoreA = 0; // Мы (или Команда А)
  int scoreB = 0; // Соперники (или Команда Б)
  
  // Controllers для ручного ввода счета
  late TextEditingController scoreAController;
  late TextEditingController scoreBController;

  // История раундов/сетов с их временем
  List<Map<String, dynamic>> rounds = [];
  
  // Данные игроков
  List<Map<String, dynamic>> playersTeamA = [];
  List<Map<String, dynamic>> playersTeamB = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    scoreAController = TextEditingController(text: scoreA.toString());
    scoreBController = TextEditingController(text: scoreB.toString());
    // 🔥 Фиксируем время начала матча как СЕЙЧАС (когда открыли экран)
    _matchStartTime = DateTime.now();
    _startTimer();
    _loadPlayers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roundTimer?.cancel();
    scoreAController.dispose();
    scoreBController.dispose();
    super.dispose();
  }

  // 👥 ЗАГРУЗИТЬ ИГРОКОВ
  Future<void> _loadPlayers() async {
    try {
      final res = await supabase
          .from('participants')
          .select('user_id, slot_index, profiles(username, avatar_url, level)')
          .eq('match_id', widget.match['id']);
      
      if (mounted) {
        setState(() {
          // Разделяем игроков по сторонам (парный падел - 4 человека)
          // Сторона А: slots 0, 1
          // Сторона Б: slots 2, 3
          for (var p in res) {
            int slotIndex = p['slot_index'] ?? -1;
            Map<String, dynamic> playerData = {
              'username': p['profiles']['username'] ?? "Игрок",
              'avatar_url': p['profiles']['avatar_url'] ?? "https://i.pravatar.cc/150",
              'level': p['profiles']['level']?.toString() ?? "?.?",
            };
            
            if (slotIndex < 2) {
              playersTeamA.add(playerData);
            } else {
              playersTeamB.add(playerData);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки игроков: $e");
    }
  }

  // ⏱️ ЛОГИКА ТАЙМЕРА МАТЧА
  void _startTimer() {
    // 🔥 Используем время открытия экрана, а не start_time из БД
    // Это предотвращает отрицательный отсчет
    
    // Запускаем обновление каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Таймер = Текущее время - Время открытия экрана
          _duration = DateTime.now().difference(_matchStartTime);
        });
      }
    });
  }

  // ⏱️ ЛОГИКА ТАЙМЕРА РАУНДА/СЕТА
  void _startRoundTimer() {
    if (_roundTimerActive) return; // Если уже активен, не запускаем заново
    
    setState(() => _roundTimerActive = true);
    
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _roundDuration = _roundDuration + const Duration(seconds: 1);
        });
      }
    });
    
    debugPrint("🎾 Таймер раунда начат!");
  }

  // ⏹️ ОСТАНОВИТЬ ТАЙМЕР РАУНДА
  void _stopRoundTimer() {
    if (!_roundTimerActive) return;
    
    _roundTimer?.cancel();
    setState(() => _roundTimerActive = false);
    
    debugPrint("⏹️ Таймер раунда остановлен! Длительность: ${_formatDuration(_roundDuration)}");
  }

  // ✅ ЗАВЕРШИТЬ РАУНД И ЗАПИСАТЬ ВРЕМЯ
  void _finishRound() {
    _stopRoundTimer();
    
    // Обновляем scoreA и scoreB из text controllers
    scoreA = int.tryParse(scoreAController.text) ?? scoreA;
    scoreB = int.tryParse(scoreBController.text) ?? scoreB;
    
    if (_roundDuration.inSeconds > 0) {
      setState(() {
        rounds.add({
          'roundNumber': rounds.length + 1,
          'duration': _roundDuration,
          'scoreA': scoreA,
          'scoreB': scoreB,
          'timestamp': DateTime.now(),
        });
        
        // 🔄 Обнуляем счет для нового раунда
        scoreA = 0;
        scoreB = 0;
        scoreAController.text = '0';
        scoreBController.text = '0';
        _roundDuration = Duration.zero;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Сет ${rounds.length} завершен за ${_formatDuration(rounds.last['duration'])}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔄 НАЧАТЬ НОВЫЙ РАУНД
  void _startNewRound() {
    _stopRoundTimer();
    setState(() {
      _roundDuration = Duration.zero;
    });
    _startRoundTimer();
  }

  // Форматирование времени в 00:00:00
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // 🏆 ЗАВЕРШЕНИЕ МАТЧА
  Future<void> _finishMatch() async {
    setState(() => _isSubmitting = true);
    
    final matchId = widget.match['id'];

    try {
      // Если сет еще активен, завершаем его
      if (_roundTimerActive) {
        _finishRound();
      }

      // Обновляем финальный счет из controllers
      scoreA = int.tryParse(scoreAController.text) ?? scoreA;
      scoreB = int.tryParse(scoreBController.text) ?? scoreB;

      // Сохраняем финальный счет и статус
      await supabase.from('matches').update({
        'status': 'FINISHED',
        'score': '$scoreA-$scoreB',
      }).eq('id', matchId);

      if (mounted) {
        // 🚀 Переходим на главный экран, закрывая весь стек навигации
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Матч завершен! Результаты сохранены. ✅"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0D1117);
    const cardColor = Color(0xFF1C1C1E);
    const neonOrange = Color(0xFFFF5500);
    const neonGreen = Color(0xFFccff00);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text("Идет игра 🎾", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- ТАБЛО ВРЕМЕНИ МАТЧА ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.black26,
            child: Column(
              children: [
                const Text("ВРЕМЯ МАТЧА", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    color: neonGreen, 
                    fontSize: 42, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),

          // --- ТАБЛО ВРЕМЕНИ СЕТА ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: _roundTimerActive ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                const Text("ВРЕМЯ СЕТА", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Text(
                  _formatDuration(_roundDuration),
                  style: TextStyle(
                    color: _roundTimerActive ? Colors.redAccent : Colors.blueAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 8),
                // КНОПКИ УПРАВЛЕНИЯ СЕТОМ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _roundTimerActive ? null : _startNewRound,
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text("Начать сет", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _roundTimerActive ? _finishRound : null,
                      icon: const Icon(Icons.stop, size: 24),
                      label: const Text("Завершить сет", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("СЧЕТ ПО СЕТУ", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // КОМАНДА 1 (МЫ)
                        Column(
                          children: [
                            const Text("ВЫ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            // 👥 Аватарки команды А
                            SizedBox(
                              height: 50,
                              width: 70,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (playersTeamA.isNotEmpty)
                                    Positioned(
                                      left: 0,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(playersTeamA[0]['avatar_url']),
                                      ),
                                    ),
                                  if (playersTeamA.length > 1)
                                    Positioned(
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(playersTeamA[1]['avatar_url']),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: TextField(
                                controller: scoreAController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFccff00), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(0),
                                ),
                                onTap: () {
                                  // Выделяем все текст при клике
                                  scoreAController.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: scoreAController.text.length,
                                  );
                                },
                                onChanged: (value) {
                                  setState(() {
                                    scoreA = int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // РАЗДЕЛИТЕЛЬ
                        const Text("VS", style: TextStyle(color: Colors.white24, fontSize: 24, fontWeight: FontWeight.bold)),
                        
                        // КОМАНДА 2 (СОПЕРНИКИ)
                        Column(
                          children: [
                            const Text("СОПЕРНИК", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            // 👥 Аватарки команды Б
                            SizedBox(
                              height: 50,
                              width: 70,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (playersTeamB.isNotEmpty)
                                    Positioned(
                                      left: 0,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(playersTeamB[0]['avatar_url']),
                                      ),
                                    ),
                                  if (playersTeamB.length > 1)
                                    Positioned(
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(playersTeamB[1]['avatar_url']),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: TextField(
                                controller: scoreBController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFccff00), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(0),
                                ),
                                onTap: () {
                                  // Выделяем все текст при клике
                                  scoreBController.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: scoreBController.text.length,
                                  );
                                },
                                onChanged: (value) {
                                  setState(() {
                                    scoreB = int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- ИСТОРИЯ СЕТОВ ---
          if (rounds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              color: Colors.black12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📊 История сетов",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: rounds.length,
                      itemBuilder: (context, index) {
                        final round = rounds[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Сет ${round['roundNumber']}",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formatDuration(round['duration']),
                                style: const TextStyle(color: Color(0xFFccff00), fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${round['scoreA']}-${round['scoreB']}",
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // --- КНОПКА ЗАВЕРШИТЬ ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSubmitting ? null : _finishMatch,
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ЗАВЕРШИТЬ МАТЧ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}