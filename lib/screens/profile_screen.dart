import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final Color _darkBg = const Color(0xFF0F172A);
  
  // --- ПЕРЕМЕННЫЕ ---
  bool _isLoading = false;
  String? _avatarUrl;
  String _username = "Игрок"; 
  double playerLevel = 3.00; 

  // СТАТИСТИКА
  int totalMatches = 24;
  int wins = 18;
  int loses = 6;
  int mvpCount = 8;
  int winRate = 75;

  // 🔥 СКИЛЛЫ
  Map<String, double> stats = {
    'SMA': 75.0, // Smash
    'VOL': 80.0, // Volley
    'LOB': 70.0, // Lob
    'DEF': 65.0, // Defense
    'SPD': 72.0, // Speed
    'PWR': 60.0  // Power
  };

  // ИСТОРИЯ (ПОЛНАЯ)
  final List<Map<String, dynamic>> matchHistory = [
    {"date": "24 Янв", "result": "WIN", "score": "6-3, 6-4", "opponent": "Клуб Padel Pro"},
    {"date": "20 Янв", "result": "WIN", "score": "7-5, 6-2", "opponent": "Arena Center"},
    {"date": "18 Янв", "result": "LOSE", "score": "4-6, 4-6", "opponent": "Tenerife Top"},
    {"date": "15 Янв", "result": "WIN", "score": "6-0, 6-1", "opponent": "Padel Z"},
    {"date": "10 Янв", "result": "WIN", "score": "6-4, 7-6", "opponent": "Home Court"},
  ];

  int _selectedChartPeriod = 1; 
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadProfile();
    _animController.forward(); 
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      
      _username = data['username'] ?? 'Игрок';
      _avatarUrl = data['avatar_url'];
      
      // 👇👇👇 ДОБАВЬ ВОТ ЭТОТ БЛОК 👇👇👇
      if (data['level'] != null) {
        setState(() {
          playerLevel = (data['level'] as num).toDouble();
        });
      }
      // 👆👆👆 КОНЕЦ ВСТАВКИ 👆👆👆

      // Загружаем скиллы
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
      debugPrint("Ошибка: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';

      await _supabase.storage.from('avatars').uploadBinary(
        fileName, bytes, fileOptions: const FileOptions(upsert: true)
      );
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

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
      // 👇 ВОТ ЭТА МАГИЧЕСКАЯ ДОБАВКА, КОТОРАЯ ЧИНИТ ВСЁ:
      await _supabase.from('profiles').update({
        'stats': stats,
        'level': playerLevel, // Теперь мы сохраняем уровень!
      }).eq('id', userId);
      
      if (mounted) {
         Navigator.pop(context); // Закрываем окно
         _showSnack("Профиль сохранен!", true);
         // Опционально: можно заставить обновиться, но проще перезайти на вкладку
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(top: 25, left: 25, right: 25, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
            height: MediaQuery.of(context).size.height * 0.85,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Редактор Профиля", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Уровень (NTRP)", style: TextStyle(color: Colors.white70)),
                            Text(playerLevel.toStringAsFixed(1), style: TextStyle(color: _getLevelColor(playerLevel), fontSize: 24, fontWeight: FontWeight.bold)),
                        ]),
                        Slider(value: playerLevel, min: 1.0, max: 7.0, divisions: 60, activeColor: _getLevelColor(playerLevel), inactiveColor: Colors.black26, onChanged: (val) { setModalState(() => playerLevel = val); setState(() => playerLevel = val); }),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  ...stats.keys.map((key) {
                    return Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(stats[key]!.toInt().toString(), style: const TextStyle(color: Colors.grey)),
                        ]),
                        SliderTheme(
                             data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay),
                             child: Slider(value: stats[key]!, min: 0, max: 99, activeColor: Colors.blue, inactiveColor: Colors.white10, onChanged: (val) { setModalState(() => stats[key] = val); setState(() => stats[key] = val); }),
                        ),
                        const SizedBox(height: 10),
                    ]);
                  }).toList(),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _getLevelColor(playerLevel), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _saveStats, child: const Text("Сохранить", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          );
        }
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
        title: const Text("ПРОФИЛЬ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _getLevelColor(playerLevel))) 
        : FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // 1. 🔥 ГИБРИДНАЯ КАРТОЧКА (Щит + Баннер + Динамический цвет)
                  _buildHybridCard(),
                  
                  const SizedBox(height: 40),
                  
                  // 2. 📊 СТАТИСТИКА
                  _buildNeonStatsGrid(),
                  
                  const SizedBox(height: 40),
                  
                  // 3. 📈 ГРАФИК ПРОГРЕССА (ПОЛНЫЙ)
                  _buildProgressChart(),
                  
                  const SizedBox(height: 40),
                  
                  // 4. 📝 ИСТОРИЯ МАТЧЕЙ (ПОЛНАЯ)
                  _buildHistorySection(),
                  
                  const SizedBox(height: 50),
                  Opacity(opacity: 0.5, child: Icon(Icons.sports_tennis, size: 40, color: _getLevelColor(playerLevel))),
                  const SizedBox(height: 10),
                  const Opacity(opacity: 0.5, child: Text("PADEL IQ PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3))),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  // --- 🔥 ГИБРИДНАЯ КАРТОЧКА ---
  Widget _buildHybridCard() {
    double cardWidth = 320;
    double cardHeight = 520; // Чуть выше из-за баннера

    return GestureDetector(
      onTap: _uploadPhoto,
      child: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 20))]
          ),
          // 👇 ИСПОЛЬЗУЕМ ЭЛЕГАНТНЫЙ ЩИТ
          child: ClipPath(
            clipper: ElegantShieldClipper(),
            child: Column(
              children: [
                // 1. ЗОЛОТОЙ БАННЕР СВЕРХУ (Фиксированный цвет)
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF2C94C), Color(0xFFD4AF37)]),
                    border: Border(bottom: BorderSide(color: Colors.white30, width: 1))
                  ),
                  child: const Center(child: Text("PADEL PRO PLAYER", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 3))),
                ),

                // 2. ОСНОВНОЕ ТЕЛО КАРТОЧКИ (ДИНАМИЧЕСКИЙ ЦВЕТ!)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getLevelGradient(playerLevel), // 🔥 Цвет меняется от уровня
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: Opacity(opacity: 0.15, child: Image.network('https://www.transparenttextures.com/patterns/cubes.png', fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container()))),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), // Отступ снизу больше из-за формы
                          child: Column(
                            children: [
                              // Верх: Рейтинг и Фото
                              Expanded(
                                flex: 3,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(playerLevel.toStringAsFixed(1), style: const TextStyle(fontSize: 55, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                                        Text(_getLevelTitle(playerLevel), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                        const SizedBox(height: 15),
                                        Container(height: 1, width: 30, color: Colors.white30),
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

                              // Имя
                              Text(_username.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5), textAlign: TextAlign.center, maxLines: 1),
                              
                              const SizedBox(height: 15),

                              // Паутинка внизу
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
      ),
    );
  }

  // --- ОСТАЛЬНЫЕ БЛОКИ (ПОЛНЫЕ ВЕРСИИ) ---
  Widget _buildNeonStatsGrid() {
    return Column(children: [
        Row(children: [_statBox("Матчей", "$totalMatches", Colors.blue, Icons.sports_tennis), const SizedBox(width: 15), _statBox("Винрейт", "$winRate%", Colors.purple, Icons.pie_chart)]),
        const SizedBox(height: 15),
        Row(children: [_statBox("Победы", "$wins", Colors.green, Icons.emoji_events), const SizedBox(width: 15), _statBox("MVP", "$mvpCount", Colors.orange, Icons.star)]),
    ]);
  }

  Widget _statBox(String label, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      ),
    );
  }

  // 🔥 ГРАФИК ПРОГРЕССА (ПОЛНЫЙ)
  Widget _buildProgressChart() {
    List<FlSpot> spots = [];
    if (_selectedChartPeriod == 0) spots = [const FlSpot(0, 2.9), const FlSpot(1, 2.95), const FlSpot(2, 3.0), FlSpot(3, playerLevel)];
    else if (_selectedChartPeriod == 1) spots = [const FlSpot(0, 1.5), const FlSpot(1, 2.0), const FlSpot(2, 2.2), const FlSpot(3, 2.5), const FlSpot(4, 2.8), FlSpot(5, playerLevel)];
    else spots = [const FlSpot(0, 1.0), const FlSpot(1, 1.5), const FlSpot(2, 2.0), const FlSpot(3, 2.5), const FlSpot(4, 2.9), FlSpot(5, playerLevel)];

    Color currentColor = _getLevelColor(playerLevel);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("ПРОГРЕСС", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4), child: Row(children: [_chartBtn("1M", 0, currentColor), const SizedBox(width: 5), _chartBtn("6M", 1, currentColor), const SizedBox(width: 5), _chartBtn("1Y", 2, currentColor)])),
        ]),
        const SizedBox(height: 15),
        Container(height: 220, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
          child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
              titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), minX: 0, maxX: spots.last.x, minY: 0, maxY: 7.5,
              lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: currentColor, barWidth: 3, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: true, color: currentColor.withOpacity(0.15)))]
          ), duration: const Duration(milliseconds: 500)),
        ),
    ]);
  }

  Widget _chartBtn(String text, int index, Color activeColor) {
    bool active = _selectedChartPeriod == index;
    return GestureDetector(onTap: () => setState(() => _selectedChartPeriod = index), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: active ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: active ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))));
  }

  // 🔥 ИСТОРИЯ МАТЧЕЙ (ПОЛНАЯ)
  Widget _buildHistorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("ИСТОРИЯ ИГР", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: matchHistory.length, separatorBuilder: (c, i) => const SizedBox(height: 10), itemBuilder: (context, index) {
            final match = matchHistory[index];
            bool isWin = match['result'] == "WIN";
            return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)), child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: isWin ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text(match['result'][0], style: TextStyle(color: isWin ? Colors.green : Colors.red, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(match['opponent'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(match['date'], style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
                  Text(match['score'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]));
        }),
    ]);
  }
}

// --- ЭЛЕГАНТНЫЙ КЛИППЕР (ПЛАВНЫЕ ЛИНИИ) ---
class ElegantShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;
    // Начало сверху слева (с отступом для закругления)
    path.moveTo(w * 0.1, 0);
    // Верхняя прямая линия
    path.lineTo(w * 0.9, 0);
    // Плавный верхний правый угол
    path.quadraticBezierTo(w, 0, w, h * 0.1);
    // Правая сторона вниз
    path.lineTo(w, h * 0.65);
    // Плавный изгиб вниз к центру (элегантное острие)
    path.quadraticBezierTo(w, h * 0.9, w * 0.5, h);
    // Плавный изгиб вверх от центра влево
    path.quadraticBezierTo(0, h * 0.9, 0, h * 0.65);
    // Левая сторона вверх
    path.lineTo(0, h * 0.1);
    // Плавный верхний левый угол
    path.quadraticBezierTo(0, 0, w * 0.1, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}