import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'match_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final Color _darkBg = const Color(0xFF0F172A);

  // --- ПЕРЕМЕННЫЕ ---
  bool _isLoading = false;
  String? _avatarUrl;
  String _username = "Игрок";
  String _city = "Benidorm, ES";
  double playerLevel = 3.00;

  // СТАТИСТИКА (Теперь считается автоматически)
  int totalMatches = 0;
  int wins = 0;
  int loses = 0;
  int mvpCount = 0;
  int winRate = 0;

  // СКИЛЛЫ
  Map<String, double> stats = {
    'SMA': 75.0,
    'VOL': 80.0,
    'LOB': 70.0,
    'DEF': 65.0,
    'SPD': 72.0,
    'PWR': 60.0
  };

  // ИСТОРИЯ (Реальная)
  List<Map<String, dynamic>> matchHistory = [];

  // КАЛЕНДАРЬ
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  int _selectedChartPeriod = 1;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    
    // Инициализация календаря
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _loadAllData();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProfile(),
      _loadMatchHistory(),
    ]);
    setState(() => _isLoading = false);
  }

  // 1. ЗАГРУЗКА ПРОФИЛЯ
  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();

      if (mounted) {
        setState(() {
          _username = data['username'] ?? 'Игрок';
          _avatarUrl = data['avatar_url'];
          _city = data['city'] ?? "Benidorm, ES";
          if (data['level'] != null)
            playerLevel = (data['level'] as num).toDouble();

          if (data['stats'] != null) {
            final Map<String, dynamic> loadedStats = data['stats'];
            loadedStats.forEach((key, value) {
              if (stats.containsKey(key))
                stats[key] = (value as num).toDouble();
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Ошибка профиля: $e");
    }
  }

  // 2. ЗАГРУЗКА ИСТОРИИ И ПОДСЧЕТ СТАТИСТИКИ
  Future<void> _loadMatchHistory() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('matches')
          .select()
          .eq('creator_id', userId)
          .not('score', 'is', null)
          .order('date', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> loadedHistory = [];
      final Map<DateTime, List<Map<String, dynamic>>> eventsMap = {};
      int w = 0;
      int l = 0;

      for (var match in response) {
        final score = match['score'] as String;
        final winnerId = match['winner_id'];
        final startTime =
            DateTime.tryParse(match['start_time'].toString()) ?? DateTime.now();
        final date = DateTime(startTime.year, startTime.month, startTime.day);
        final location = match['location'] ?? "Unknown Club";

        bool isWin = winnerId == userId;
        if (isWin) w++;
        else l++;

        // Добавить в историю с форматированной датой
        loadedHistory.add({
          "date": DateFormat('d MMM').format(startTime),
          "result": isWin ? "WIN" : "LOSE",
          "score": score,
          "opponent": location,
          "match_id": match['id'],
          "start_time": startTime,
          "status": match['status'],
        });

        // Добавить в календарь событий
        if (!eventsMap.containsKey(date)) {
          eventsMap[date] = [];
        }
        eventsMap[date]!.add({
          "match_id": match['id'],
          "start_time": startTime,
          "location": location,
          "score": score,
          "result": isWin ? "WIN" : "LOSE",
          "status": match['status'],
        });
      }

      if (mounted) {
        setState(() {
          matchHistory = loadedHistory;
          _events = eventsMap;
          totalMatches = loadedHistory.length;
          wins = w;
          loses = l;
          winRate =
              totalMatches > 0 ? ((wins / totalMatches) * 100).toInt() : 0;
        });
      }
    } catch (e) {
      debugPrint("Ошибка истории: $e");
    }
  }

  // ✏️ РЕДАКТИРОВАНИЕ
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _username);
    final cityController = TextEditingController(text: _city);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Редактировать профиль",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Имя игрока",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _getLevelColor(playerLevel))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Город / Клуб",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _getLevelColor(playerLevel))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _getLevelColor(playerLevel)),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newCity = cityController.text.trim();
              if (newName.isEmpty) return;

              try {
                final uid = _supabase.auth.currentUser!.id;
                await _supabase.from('profiles').update({
                  'username': newName,
                  'city': newCity,
                }).eq('id', uid);

                setState(() {
                  _username = newName;
                  _city = newCity;
                });
                Navigator.pop(context);
                _showSnack("Профиль обновлен ✅", true);
              } catch (e) {
                _showSnack("Ошибка: $e", false);
              }
            },
            child: const Text("Сохранить",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';

      await _supabase.storage.from('avatars').uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', userId);

      setState(() {
        _avatarUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      });
      if (mounted) _showSnack("Фото обновлено!", true);
    } catch (e) {
      if (mounted) _showSnack("Ошибка загрузки: $e", false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStats() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').update({
        'stats': stats,
        'level': playerLevel,
      }).eq('id', userId);

      if (mounted) {
        Navigator.pop(context);
        _showSnack("Профиль сохранен!", true);
      }
    } catch (e) {
      _showSnack("Не удалось сохранить: $e", false);
    }
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _getLevelTitle(double level) {
    if (level >= 6.0) return "PRO";
    if (level >= 4.5) return "ADVANCED";
    if (level >= 3.5) return "INTERMEDIATE";
    if (level >= 2.5) return "LOW-MID";
    return "ROOKIE";
  }

  LinearGradient _getLevelGradient(double level) {
    if (level >= 6.0)
      return const LinearGradient(
          colors: [Color(0xFF3E1E68), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    if (level >= 4.5)
      return const LinearGradient(
          colors: [Color(0xFFF2C94C), Color(0xFFAE8625)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    if (level >= 3.5)
      return const LinearGradient(
          colors: [Color(0xFF2980B9), Color(0xFF2C3E50)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    if (level >= 2.5)
      return const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    return const LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
  }

  Color _getLevelColor(double level) {
    if (level >= 6.0) return const Color(0xFF8E2DE2);
    if (level >= 4.5) return const Color(0xFFF2C94C);
    if (level >= 3.5) return const Color(0xFF2980B9);
    if (level >= 2.5) return const Color(0xFF00F2FE);
    return const Color(0xFF43E97B);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
              top: 25,
              left: 25,
              right: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 40),
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text("Редактор Навыков",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Уровень (NTRP)",
                              style: TextStyle(color: Colors.white70)),
                          Text(playerLevel.toStringAsFixed(1),
                              style: TextStyle(
                                  color: _getLevelColor(playerLevel),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ]),
                    Slider(
                        value: playerLevel,
                        min: 1.0,
                        max: 7.0,
                        divisions: 60,
                        activeColor: _getLevelColor(playerLevel),
                        inactiveColor: Colors.black26,
                        onChanged: (val) {
                          setModalState(() => playerLevel = val);
                          setState(() => playerLevel = val);
                        }),
                  ]),
                ),
                const SizedBox(height: 20),
                ...stats.keys.map((key) {
                  return Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(key,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(stats[key]!.toInt().toString(),
                              style: const TextStyle(color: Colors.grey)),
                        ]),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: SliderComponentShape.noOverlay),
                      child: Slider(
                          value: stats[key]!,
                          min: 0,
                          max: 99,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.white10,
                          onChanged: (val) {
                            setModalState(() => stats[key] = val);
                            setState(() => stats[key] = val);
                          }),
                    ),
                    const SizedBox(height: 10),
                  ]);
                }).toList(),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _getLevelColor(playerLevel),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: _saveStats,
                        child: const Text("Сохранить",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        );
      }),
    );
  }

  // 📜 КОПИРАЙТ И ЛИЦЕНЗИЯ
  void _showCopyright() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "© PADEL IQ PRO",
          style: TextStyle(
            color: Color(0xFFccff00),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Copyright © 2026",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Andrii Kosiak",
                      style: TextStyle(
                        color: Color(0xFFccff00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "All rights reserved.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Unauthorized copying, modification, or redistribution of this software is strictly prohibited.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  "🔒 DMCA Protected: Reverse engineering prohibited by law",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ОК",
              style: TextStyle(color: Color(0xFFccff00)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("ПРОФИЛЬ",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        actions: [
          IconButton(
              icon: const Icon(Icons.copyright, color: Colors.grey),
              onPressed: _showCopyright),
          IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: _openSettings)
        ],
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: _getLevelColor(playerLevel)))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    _buildHybridCard(),
                    const SizedBox(height: 40),
                    _buildNeonStatsGrid(),
                    const SizedBox(height: 40),
                    _buildProgressChart(),
                    const SizedBox(height: 40),
                    _buildHistorySection(),
                    const SizedBox(height: 50),
                    // 🔥 ЗАМЕНИЛИ ИКОНКУ НА ЛОГОТИП 🔥
                    Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/logo.png',
                          height: 40,
                          color: _getLevelColor(
                              playerLevel), // Логотип окрашивается в цвет уровня
                        )),
                    const SizedBox(height: 10),
                    //const Opacity(opacity: 0.5, child: Text("PADEL IQ PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3))),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHybridCard() {
    double cardWidth = 320;
    double cardHeight = 520;

    return GestureDetector(
      onTap: _uploadPhoto,
      child: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 20))
          ]),
          child: ClipPath(
            clipper: ElegantShieldClipper(),
            child: Column(
              children: [
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFFD4AF37),
                        Color(0xFFF2C94C),
                        Color(0xFFD4AF37)
                      ]),
                      border: Border(
                          bottom: BorderSide(color: Colors.white30, width: 1))),
                  child: const Center(
                      child: Text("PADEL PRO PLAYER",
                          style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 3))),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getLevelGradient(playerLevel),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: Opacity(
                                opacity: 0.15,
                                child: Image.network(
                                    'https://www.transparenttextures.com/patterns/cubes.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container()))),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(playerLevel.toStringAsFixed(1),
                                            style: const TextStyle(
                                                fontSize: 55,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1)),
                                        Text(_getLevelTitle(playerLevel),
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1)),
                                        const SizedBox(height: 15),
                                        Container(
                                            height: 1,
                                            width: 30,
                                            color: Colors.white30),
                                        const SizedBox(height: 10),
                                        const Text("🇺🇦",
                                            style: TextStyle(fontSize: 30)),
                                      ],
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          height: 150,
                                          width: 150,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  width: 3),
                                              image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: _avatarUrl != null
                                                      ? NetworkImage(
                                                          _avatarUrl!)
                                                      : const NetworkImage(
                                                          'https://i.pravatar.cc/300'))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_username.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.5)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _showEditProfileDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Icon(Icons.edit,
                                          color: Colors.white, size: 14),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(_city,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      letterSpacing: 1)),
                              const SizedBox(height: 15),
                              Expanded(
                                flex: 3,
                                child: RadarChart(
                                  RadarChartData(
                                    dataSets: [
                                      RadarDataSet(
                                        fillColor:
                                            Colors.white.withOpacity(0.2),
                                        borderColor:
                                            Colors.white.withOpacity(0.9),
                                        entryRadius: 2,
                                        dataEntries: stats.values
                                            .map((v) => RadarEntry(value: v))
                                            .toList(),
                                        borderWidth: 2,
                                      ),
                                    ],
                                    radarBackgroundColor: Colors.transparent,
                                    borderData: FlBorderData(show: false),
                                    radarBorderData: const BorderSide(
                                        color: Colors.white38, width: 1),
                                    titleTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    titlePositionPercentageOffset: 0.1,
                                    getTitle: (index, angle) => RadarChartTitle(
                                        text: stats.keys.elementAt(index)),
                                    tickCount: 1,
                                    ticksTextStyle: const TextStyle(
                                        color: Colors.transparent),
                                    gridBorderData: const BorderSide(
                                        color: Colors.white12, width: 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonStatsGrid() {
    return Column(children: [
      Row(children: [
        _statBox("Матчей", "$totalMatches", Colors.blue, Icons.sports_tennis),
        const SizedBox(width: 15),
        _statBox("Винрейт", "$winRate%", Colors.purple, Icons.pie_chart)
      ]),
      const SizedBox(height: 15),
      Row(children: [
        _statBox("Победы", "$wins", Colors.green, Icons.emoji_events),
        const SizedBox(width: 15),
        _statBox("MVP", "$mvpCount", Colors.orange, Icons.star)
      ]),
    ]);
  }

  Widget _statBox(String label, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildProgressChart() {
    List<FlSpot> spots = [];
    if (_selectedChartPeriod == 0)
      spots = [
        const FlSpot(0, 2.9),
        const FlSpot(1, 2.95),
        const FlSpot(2, 3.0),
        FlSpot(3, playerLevel)
      ];
    else if (_selectedChartPeriod == 1)
      spots = [
        const FlSpot(0, 1.5),
        const FlSpot(1, 2.0),
        const FlSpot(2, 2.2),
        const FlSpot(3, 2.5),
        const FlSpot(4, 2.8),
        FlSpot(5, playerLevel)
      ];
    else
      spots = [
        const FlSpot(0, 1.0),
        const FlSpot(1, 1.5),
        const FlSpot(2, 2.0),
        const FlSpot(3, 2.5),
        const FlSpot(4, 2.9),
        FlSpot(5, playerLevel)
      ];

    Color currentColor = _getLevelColor(playerLevel);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("ПРОГРЕСС",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _chartBtn("1M", 0, currentColor),
              const SizedBox(width: 5),
              _chartBtn("6M", 1, currentColor),
              const SizedBox(width: 5),
              _chartBtn("1Y", 2, currentColor)
            ])),
      ]),
      const SizedBox(height: 15),
      Container(
        height: 220,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10)),
        child: LineChart(
            LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.white10, strokeWidth: 1)),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.last.x,
                minY: 0,
                maxY: 7.5,
                lineBarsData: [
                  LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: currentColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: currentColor.withOpacity(0.15)))
                ]),
            duration: const Duration(milliseconds: 500)),
      ),
    ]);
  }

  Widget _chartBtn(String text, int index, Color activeColor) {
    bool active = _selectedChartPeriod == index;
    return GestureDetector(
        onTap: () => setState(() => _selectedChartPeriod = index),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: active ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8)),
            child: Text(text,
                style: TextStyle(
                    color: active ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))));
  }

  Widget _buildHistorySection() {
    if (matchHistory.isEmpty) {
      return Column(
        children: const [
          Icon(Icons.history, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text("Игр пока нет", style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    // Получить события для выбранного дня
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedEvents = _events[selectedDate] ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("МОЯ АКТИВНОСТЬ",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      
      // КАЛЕНДАРЬ
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            final dayDate = DateTime(day.year, day.month, day.day);
            return _events[dayDate] ?? [];
          },
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: Colors.white70),
            weekendTextStyle: const TextStyle(color: Colors.white70),
            selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            outsideTextStyle: const TextStyle(color: Colors.grey),
            selectedDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white70, fontSize: 12),
            weekendStyle: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox();
              
              // Определить цвет по статусу матча
              try {
                final event = events.first as Map<String, dynamic>;
                final startTime = event['start_time'] as DateTime;
                final isPast = startTime.isBefore(DateTime.now());
                final color = isPast ? Colors.red : Colors.green;
                
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              } catch (e) {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
      
      const SizedBox(height: 20),
      
      // МАТЧИ НА ВЫБРАННЫЙ ДЕНЬ
      if (selectedEvents.isNotEmpty) ...[
        Text(
          "Игры на ${DateFormat('d MMMM y').format(_selectedDay)}",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...selectedEvents.map((event) {
          final startTime = event['start_time'] as DateTime;
          final isPast = startTime.isBefore(DateTime.now());
          final isWin = event['result'] == 'WIN';
          
          return GestureDetector(
            onTap: () {
              // Навигация на деталь матча
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailsScreen(
                    matchId: event['match_id'],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPast ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        event['result'][0],
                        style: TextStyle(
                          color: isPast ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['location'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(startTime),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    event['score'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ] else
        Center(
          child: Text(
            "Нет игр на выбранную дату",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
    ]);
  }
}

class ElegantShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;
    path.moveTo(w * 0.1, 0);
    path.lineTo(w * 0.9, 0);
    path.quadraticBezierTo(w, 0, w, h * 0.1);
    path.lineTo(w, h * 0.65);
    path.quadraticBezierTo(w, h * 0.9, w * 0.5, h);
    path.quadraticBezierTo(0, h * 0.9, 0, h * 0.65);
    path.lineTo(0, h * 0.1);
    path.quadraticBezierTo(0, 0, w * 0.1, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
