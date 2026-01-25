import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final Color _darkBg = const Color(0xFF0F172A);
  
  bool _isLoading = false;
  String? _avatarUrl;
  String _username = "Игрок"; 
  double playerLevel = 3.00; // Сюда загрузим реальный уровень
  
  Map<String, double> stats = {
    'SMA': 75.0, 'VOL': 80.0, 'LOB': 70.0,
    'DEF': 65.0, 'SPD': 72.0, 'PWR': 60.0
  };

  int totalMatches = 24;
  int wins = 18;
  int winRate = 75;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      
      _username = data['username'] ?? 'Игрок';
      _avatarUrl = data['avatar_url'];
      
      // 👇 ВАЖНОЕ ИСПРАВЛЕНИЕ: Загружаем уровень из базы
      if (data['level'] != null) {
        setState(() {
          playerLevel = (data['level'] as num).toDouble();
        });
      }

      if (data['stats'] != null) {
        final Map<String, dynamic> loadedStats = data['stats'];
        setState(() {
          loadedStats.forEach((key, value) {
            if (stats.containsKey(key)) {
              stats[key] = (value as num).toDouble();
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки на главном: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

 // 1. ТИТУЛЫ (Вернули все ранги)
  String _getLevelTitle(double level) {
    if (level >= 6.0) return "PRO";
    if (level >= 4.5) return "ADVANCED"; // (ADV)
    if (level >= 3.5) return "INTERMEDIATE"; // (INT)
    if (level >= 2.5) return "LOW-MID"; // (MID)
    return "ROOKIE"; // (ROK)
  }

  // 2. ГРАДИЕНТЫ (Вернули Зеленый и Голубой)
  LinearGradient _getLevelGradient(double level) {
    // PRO (Фиолетовый/Черный)
    if (level >= 6.0) return const LinearGradient(colors: [Color(0xFF3E1E68), Color(0xFF000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    // ADVANCED (Золото)
    if (level >= 4.5) return const LinearGradient(colors: [Color(0xFFF2C94C), Color(0xFFAE8625)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    // INTERMEDIATE (Синий)
    if (level >= 3.5) return const LinearGradient(colors: [Color(0xFF2980B9), Color(0xFF2C3E50)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    // MID (Голубой / Cyan) - ВЕРНУЛИ!
    if (level >= 2.5) return const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    // ROOKIE (Зеленый) - ВЕРНУЛИ!
    return const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
  }

  // 3. ЦВЕТА ЭЛЕМЕНТОВ (Для иконок и текстов)
  Color _getLevelColor(double level) {
    if (level >= 6.0) return const Color(0xFF8E2DE2);
    if (level >= 4.5) return const Color(0xFFF2C94C);
    if (level >= 3.5) return const Color(0xFF2980B9);
    if (level >= 2.5) return const Color(0xFF00F2FE); // Cyan
    return const Color(0xFF43E97B); // Green
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ГЛАВНАЯ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white))
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2C94C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Карточка (теперь динамическая!)
                  _buildHomeCard(),

                  const SizedBox(height: 30),
                  _buildQuickStats(),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: const Color(0xFF2F80ED).withOpacity(0.5)
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.sports_tennis, color: Colors.white),
                      label: const Text("НАЙТИ ИГРУ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHomeCard() {
    double cardWidth = 320;
    double cardHeight = 500;

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 20))]
        ),
        child: ClipPath(
          clipper: ElegantShieldClipper(), 
          child: Column(
            children: [
              // Баннер
              Container(
                height: 50,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF2C94C), Color(0xFFD4AF37)]),
                  border: Border(bottom: BorderSide(color: Colors.white30, width: 1))
                ),
                child: const Center(child: Text("PADEL PRO PLAYER", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 3))),
              ),

              // Тело карточки (Цвет зависит от уровня!)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _getLevelGradient(playerLevel), // 🔥 ВОТ ЗДЕСЬ МАГИЯ ЦВЕТА
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Opacity(opacity: 0.15, child: Image.network('https://www.transparenttextures.com/patterns/cubes.png', fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container()))),
                      
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
                                      Text(playerLevel.toStringAsFixed(1), style: const TextStyle(fontSize: 55, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                                      Text(_getLevelTitle(playerLevel), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 10),
                                      const Text("🇺🇦", style: TextStyle(fontSize: 30)), 
                                    ],
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        height: 150, width: 150,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: _avatarUrl != null ? NetworkImage(_avatarUrl!) : const NetworkImage('https://i.pravatar.cc/300') 
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Text(_username.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5), textAlign: TextAlign.center, maxLines: 1),
                            const SizedBox(height: 15),

                            Expanded(
                              flex: 3,
                              child: RadarChart(
                                RadarChartData(
                                  dataSets: [
                                    RadarDataSet(
                                      fillColor: Colors.white.withOpacity(0.2),
                                      borderColor: Colors.white.withOpacity(0.9),
                                      entryRadius: 2,
                                      dataEntries: stats.values.map((v) => RadarEntry(value: v)).toList(),
                                      borderWidth: 2,
                                    ),
                                  ],
                                  radarBackgroundColor: Colors.transparent,
                                  borderData: FlBorderData(show: false),
                                  radarBorderData: const BorderSide(color: Colors.white38, width: 1),
                                  titleTextStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  titlePositionPercentageOffset: 0.1, 
                                  getTitle: (index, angle) => RadarChartTitle(text: stats.keys.elementAt(index)),
                                  tickCount: 1,
                                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                                  gridBorderData: const BorderSide(color: Colors.white12, width: 1),
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
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _homeStatItem("МАТЧИ", "$totalMatches", Colors.blue),
          Container(width: 1, height: 40, color: Colors.white10),
          _homeStatItem("ПОБЕДЫ", "$wins", Colors.green),
          Container(width: 1, height: 40, color: Colors.white10),
          _homeStatItem("ВИНРЕЙТ", "$winRate%", Colors.purple),
        ],
      ),
    );
  }

  Widget _homeStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
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