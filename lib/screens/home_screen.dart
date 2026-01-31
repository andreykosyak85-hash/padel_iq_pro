import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Для рандома советов
import '../main.dart';
import 'create_match_screen.dart';
import 'profile_screen.dart';
import 'match_details_screen.dart'; 
import 'matches_screen.dart';
import 'match_analysis_screen.dart'; // 🔥 Экран анализа (паутинка)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ЦВЕТА ---
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _neonOrange = const Color(0xFFFF5500);
  final Color _neonGreen = const Color(0xFFccff00);
  final Color _neonCyan = const Color(0xFF00E5FF);

  // --- ДАННЫЕ ---
  String _username = "Игрок";
  String _avatarUrl = "";
  double _level = 0.0;
  bool _isLoading = true;

  Map<String, dynamic>? _nextMatch;
  List<dynamic> _activeMatches = [];
  Map<String, dynamic>? _lastMatch;

  final Map<String, String> _healthStats = {
    'kcal': '0', 'bpm': '0', 'dist': '0 км', 'last_score': '...',
  };

  // Список советов для AI Тренера
  final List<String> _aiTips = [
    "«При игре у сетки держи ракетку выше уровня глаз.»",
    "«В паделе стена — твой друг. Не бойся пропускать мячи.»",
    "«Свеча (Lob) — самый важный тактический удар.»",
    "«Не бей смэш из-за линии подачи. Риск ошибки высок.»",
    "«Коммуникация важнее техники. Говорите 'Мой' или 'Твой'.»",
    "«Главное на приеме — просто вернуть мяч в игру.»"
  ];
  String _currentTip = "";

  @override
  void initState() {
    super.initState();
    _loadData();
    // Выбираем случайный совет при запуске
    _currentTip = _aiTips[Random().nextInt(_aiTips.length)];
  }

  Future<void> _loadData() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // 1. ЗАГРУЗКА ПРОФИЛЯ (Отдельно, чтобы всегда показывался)
      final profile = await supabase
          .from('profiles')
          .select('username, avatar_url, level')
          .eq('id', uid)
          .single();

      if (mounted) {
        setState(() {
          _username = profile['username'] ?? "Игрок";
          _avatarUrl = profile['avatar_url'] ?? "";
          _level = (profile['level'] ?? 0).toDouble();
        });
      }

      // 2. ЗАГРУЗКА МАТЧЕЙ
      final now = DateTime.now().toIso8601String();
      debugPrint("⏰ Current time for filtering: $now");

      // 3. Активные матчи (Публичные, в будущем)
      debugPrint("📥 Fetching active public matches...");
      final matchesData = await supabase
          .from('matches')
          .select('*, clubs(*)')
          .filter('group_id', 'is', null) // Только публичные
          .gte('start_time', now) 
          .order('start_time', ascending: true)
          .limit(10);
      debugPrint("✅ Active public matches: ${matchesData.length}");
      if (matchesData.isNotEmpty) {
        for (var m in matchesData) {
          debugPrint("   - ${m['start_time']} at ${m['clubs']?['name'] ?? m['location']}");
        }
      }

      // 4. История (Последняя СОЗДАННУЮ мною игра - независимо от времени!)
      debugPrint("📥 Fetching my last created match (any time)...");
      Map<String, dynamic>? lastMatch;
      try {
        final lastRes = await supabase.from('matches')
            .select('*, clubs(*)')
            .eq('creator_id', uid)
            // Убрали фильтр по времени! Берем просто последнюю по дате создания
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        lastMatch = lastRes;
        if (lastMatch != null) {
          debugPrint("✅ Last match found!");
          debugPrint("   ID: ${lastMatch['id']}");
          debugPrint("   Title: ${lastMatch['title']}");
          debugPrint("   Score: ${lastMatch['score']} (type: ${lastMatch['score'].runtimeType})");
          debugPrint("   Club: ${lastMatch['clubs']?['name']}");
          debugPrint("   Type: ${lastMatch['type']}");
        } else {
          debugPrint("✅ Last match: NOT FOUND");
        }
      } catch (e) {
        debugPrint("⚠️ Error loading last match: $e");
      }

      // 5. Ближайшая СОЗДАННАЯ мною игра (Будущая)
      debugPrint("📥 Fetching my next created match...");
      Map<String, dynamic>? nextMatch;
      try {
        final myNextRes = await supabase.from('matches')
            .select('*, clubs(*)')
            .eq('creator_id', uid)
            .gte('start_time', now) // Будущие матчи
            .order('start_time', ascending: true)
            .limit(1)
            .maybeSingle();
        nextMatch = myNextRes;
        debugPrint("✅ Next match: ${nextMatch != null ? nextMatch['start_time'] : 'NOT FOUND'}");
      } catch (e) {
        debugPrint("⚠️ Error loading next match: $e");
      }

      if (mounted) {
        setState(() {
          _nextMatch = nextMatch;
          
          // Активные - это список публичных, убираем оттуда свою ближайшую
          _activeMatches = List.from(matchesData);
          if (_nextMatch != null) {
             _activeMatches.removeWhere((m) => m['id'] == _nextMatch!['id']);
          }

          _lastMatch = lastMatch;

          // Статистика
          if (lastMatch != null) {
            String sc = lastMatch['score']?.toString() ?? "Завершен";
            _healthStats['last_score'] = sc.isEmpty ? "Завершен" : sc;
            _healthStats['kcal'] = "720"; 
            _healthStats['bpm'] = "148";
            _healthStats['dist'] = "5.1 км";
          } else {
            _healthStats['last_score'] = "Нет игр";
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getWinnerTeam(String score) {
    if (score == '...' || score == 'Нет игр' || score == 'Завершен' || score == 'Турнир') return 0;
    int setsA = 0;
    int setsB = 0;
    try {
      final sets = score.replaceAll(',', ' ').split(' ');
      for (var s in sets) {
        if (s.trim().isEmpty) continue;
        final parts = s.trim().split('-');
        if (parts.length == 2) {
          int a = int.tryParse(parts[0]) ?? 0;
          int b = int.tryParse(parts[1]) ?? 0;
          if (a > b) setsA++;
          if (b > a) setsB++;
        }
      }
    } catch (e) { return 0; }
    if (setsA > setsB) return 1;
    if (setsB > setsA) return 2;
    return 0;
  }

  LinearGradient _getLevelGradient(double level) {
    if (level >= 4.5) return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]);
    if (level >= 3.5) return const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]);
    if (level >= 2.5) return const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)]);
    return const LinearGradient(colors: [Color(0xFF78909C), Color(0xFF455A64)]);
  }

  String _getLevelStatus(double level) {
    if (level >= 5.5) return "PRO • Cat 1";
    if (level >= 4.5) return "ADVANCED • Cat 2";
    if (level >= 3.5) return "INTERM.+ • Cat 3";
    if (level >= 2.5) return "INTERM. • Cat 4";
    return "BEGINNER • Cat 5";
  }

  Color _getMatchColor(String type) {
    if (type.contains('Americano')) return _neonGreen;
    if (type.contains('Competitive')) return _neonOrange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Row(
          children: [
            SizedBox(
              height: 32,
              child: Image.asset(
                'assets/logo.png', // 🔥 ЛОГОТИП ВМЕСТО ИКОНКИ
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.sports_tennis, color: _neonGreen),
              ),
            ),
            const SizedBox(width: 10),
            const Text("PADEL IQ",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ВЕРХНИЙ БЛОК (Приветствие + Ближайшая игра + Профиль)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Привет, $_username! 👋",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 5),
                              const Text("Ищем игру?",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: _nextMatch == null
                                      ? _buildEmptyState()
                                      : _buildNextMatchState(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileScreen())),
                            child: Container(
                              margin: const EdgeInsets.only(top: 55),
                              decoration: BoxDecoration(
                                  gradient: _getLevelGradient(_level),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _getLevelGradient(_level)
                                            .colors
                                            .first
                                            .withOpacity(0.4),
                                        blurRadius: 10)
                                  ]),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _avatarUrl.isNotEmpty
                                        ? NetworkImage(_avatarUrl)
                                        : null,
                                    child: _avatarUrl.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_level.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text(_getLevelStatus(_level),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. АКТИВНЫЕ МАТЧИ
                  const Text("Активные матчи рядом 🔥",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  _activeMatches.isEmpty
                      ? const Text("Нет активных игр. Будьте первым!",
                          style: TextStyle(color: Colors.grey))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _activeMatches.map((match) {
                              DateTime d = DateTime.tryParse(match['start_time'].toString()) ?? DateTime.now();
                              String dateStr = "${d.day}.${d.month}";
                              String timeStr = "${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}";
                              String clubName = match['clubs'] != null 
                                  ? match['clubs']['name'] 
                                  : (match['location'] ?? "Клуб");
                              final type = match['type'] ?? "Match";

                              return Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: _buildMatchCard(
                                  clubName,
                                  "$timeStr | $dateStr",
                                  "Игрок",
                                  type,
                                  _getMatchColor(type),
                                  () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MatchDetailsScreen(match: match)));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                  const SizedBox(height: 30),

                  // 3. ПОСЛЕДНЯЯ ИГРА
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Последняя игра",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MatchesScreen(initialIndex: 2))),
                        child: Text("Все игры",
                            style: TextStyle(
                                color: _neonCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildLastMatchCard(),

                  const SizedBox(height: 20),

                  // 4. СТАТИСТИКА
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Статистика (Last Game)",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.watch, color: _neonCyan, size: 20),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildNeonStatCard("ККАЛ", _healthStats['kcal']!,
                            Icons.local_fire_department, _neonOrange),
                        const SizedBox(width: 12),
                        _buildNeonStatCard("ПУЛЬС", _healthStats['bpm']!,
                            Icons.favorite, Colors.redAccent),
                        const SizedBox(width: 12),
                        _buildNeonStatCard("ДИСТАНЦИЯ", _healthStats['dist']!,
                            Icons.directions_run, _neonCyan),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 5. AI ТРЕНЕР
                  Row(
                    children: [
                      const Text("AI Тренер & Инсайты",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: _neonCyan,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text("BETA",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFF6A11CB),
                          Color(0xFF2575FC)
                        ]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF2575FC).withOpacity(0.4),
                              blurRadius: 10)
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text("Совет дня",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            _currentTip, // 🔥 СЛУЧАЙНЫЙ СОВЕТ
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // НОВОСТИ
                  _buildNewsCard("Анализ слабых сторон",
                      "Твой бэкхенд улучшился на 15%", Icons.analytics, () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()));
                      }),
                  const SizedBox(height: 10),
                  _buildNewsCard("Турнир Valencia Open",
                      "Регистрация открыта!", Icons.emoji_events, () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Раздел турниров скоро будет доступен! 🏆")));
                      }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // --- ВИДЖЕТЫ (ВЕРНУЛ ВСЕ НА МЕСТО) ---

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Ближайшая игра:",
                style: TextStyle(color: Colors.grey, fontSize: 10)),
            SizedBox(height: 4),
            Text("Нет запланированных",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _neonOrange,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateMatchScreen())),
          child: const Text("Создать", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildNextMatchState() {
    final m = _nextMatch!;
    DateTime d = DateTime.tryParse(m['start_time'].toString()) ?? DateTime.now();
    String dateStr = "${d.day}.${d.month}";
    String timeStr = "${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}";
    String location = m['clubs'] != null ? m['clubs']['name'] : (m['location'] ?? "Клуб");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Ближайшая игра:",
                style: TextStyle(color: Color(0xFFccff00), fontSize: 10)),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateMatchScreen())),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        Text("$timeStr | $dateStr",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(location,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis),

        const Spacer(),

        OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MatchDetailsScreen(match: m)));
          },
          child: const Text("Подробнее", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  // 🔥 ИСПРАВЛЕННЫЙ БЛОК С КНОПКОЙ АНАЛИЗА
  Widget _buildLastMatchCard() {
    if (_lastMatch == null) {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _cardColor, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10)),
            child: const Text("История пуста", style: TextStyle(color: Colors.grey))
        );
    }

    // Получаем счет из самого матча, а не из _healthStats
    String score = _lastMatch!['score']?.toString() ?? "...";
    if (score.isEmpty) score = "Завершен";
    
    int winner = _getWinnerTeam(score);
    String clubName = _lastMatch!['clubs'] != null 
        ? _lastMatch!['clubs']['name'] 
        : (_lastMatch!['location'] ?? "Клуб");
    String type = _lastMatch!['type'] ?? "Match";

    debugPrint("📊 Last match score: $score, Winner: $winner");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Прошлая • $clubName",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(type,
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (winner == 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: _neonGreen,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text("WIN",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox(height: 18),
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        backgroundImage: _avatarUrl.isNotEmpty
                            ? NetworkImage(_avatarUrl)
                            : null,
                        child: _avatarUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 24, color: Colors.white)
                            : null),
                    const SizedBox(height: 8),
                    const Text("Вы",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(score,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (winner == 2)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: _neonGreen,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text("WIN",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox(height: 18),
                    const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        child:
                            Icon(Icons.group, color: Colors.white, size: 24)),
                    const SizedBox(height: 8),
                    const Text("Соперники",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 🔥 ИСПРАВЛЕННАЯ КНОПКА (БЕЗ child: ОШИБКИ)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MatchAnalysisScreen()))
                    .then((result) {
                  if (result == true) {
                    debugPrint("🔄 Reloading data after skills update...");
                    _loadData();
                  }
                });
              },
              icon: const Icon(Icons.analytics_outlined,
                  size: 18, color: Colors.white),
              label: const Text("Оценить свою игру",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMatchCard(String club, String time, String creator, String type,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(type,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text(time,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(club,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(creator,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    elevation: 0,
                    padding: EdgeInsets.zero),
                child: const Text("Войти",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNeonStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1), blurRadius: 8, spreadRadius: 0)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _cardColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}