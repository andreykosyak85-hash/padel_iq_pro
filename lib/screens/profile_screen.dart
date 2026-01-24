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
  
  // --- ПЕРЕМЕННЫЕ СОСТОЯНИЯ ---
  bool _isLoading = false;
  String? _avatarUrl;
  String _username = "Игрок"; 
  
  // РЕЙТИНГ (1.0 - 7.0)
  double playerLevel = 3.00; 

  // СТАТИСТИКА (ГЛОБАЛЬНАЯ)
  int totalMatches = 24;
  int wins = 18;
  int loses = 6;
  int winStreak = 5;
  int mvpCount = 8;
  int winRate = 75;

  // ГЕЙМИФИКАЦИЯ (Скиллы - FIFA Style)
  // Используем английские сокращения для графика, чтобы они влезали
  Map<String, double> stats = {
    'PAC': 75.0, // Скорость
    'SHO': 60.0, // Удар
    'PAS': 70.0, // Пас
    'DRI': 80.0, // Дриблинг
    'DEF': 40.0, // Защита
    'PHY': 65.0  // Физика
  };

  // ИСТОРИЯ МАТЧЕЙ
  final List<Map<String, dynamic>> matchHistory = [
    {"date": "24 Янв", "result": "WIN", "score": "6-3, 6-4", "opponent": "Клуб Padel Pro"},
    {"date": "20 Янв", "result": "WIN", "score": "7-5, 6-2", "opponent": "Arena Center"},
    {"date": "18 Янв", "result": "LOSE", "score": "4-6, 4-6", "opponent": "Tenerife Top"},
    {"date": "15 Янв", "result": "WIN", "score": "6-0, 6-1", "opponent": "Padel Z"},
    {"date": "10 Янв", "result": "WIN", "score": "6-4, 7-6", "opponent": "Home Court"},
  ];

  // Переменная для графика (0=1M, 1=6M, 2=1Y)
  int _selectedChartPeriod = 1; 

  // Анимация
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

  // --- ЗАГРУЗКА ---
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      
      _username = data['username'] ?? 'Игрок';
      _avatarUrl = data['avatar_url'];
      
      // Загружаем скиллы безопасно
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
      await _supabase.from('profiles').update({'stats': stats}).eq('id', userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack("Не удалось сохранить", false);
    }
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- ЦВЕТА И РАНГИ ---
  String _getLevelTitle(double level) {
    if (level >= 6.0) return "MASTER / PRO";
    if (level >= 4.5) return "ADVANCED (Cat A)";
    if (level >= 3.5) return "INTERMEDIATE (Cat B)";
    if (level >= 2.5) return "LOW-MID (Cat C)";
    return "ROOKIE (Cat D)";
  }

  LinearGradient _getLevelGradient(double level) {
    if (level >= 6.0) return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF000000)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    if (level >= 4.5) return const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C), Color(0xFFd4af37)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    if (level >= 3.5) return const LinearGradient(colors: [Color(0xFF2980B9), Color(0xFF6DD5FA), Color(0xFF4286f4)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    if (level >= 2.5) return const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    return const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  Color _getLevelColor(double level) {
    if (level >= 6.0) return const Color(0xFF8E2DE2);
    if (level >= 4.5) return const Color(0xFFF2994A);
    if (level >= 3.5) return const Color(0xFF2980B9);
    if (level >= 2.5) return const Color(0xFF00F2FE);
    return const Color(0xFF43E97B);
  }

  // --- МЕНЮ НАСТРОЕК (FULL) ---
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
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
                  
                  // Слайдер уровня
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Уровень (NTRP)", style: TextStyle(color: Colors.white70)),
                            Text(playerLevel.toStringAsFixed(1), style: TextStyle(color: _getLevelColor(playerLevel), fontSize: 24, fontWeight: FontWeight.bold)),
                        ]),
                        Slider(value: playerLevel, min: 1.0, max: 7.0, divisions: 60, activeColor: _getLevelColor(playerLevel), inactiveColor: Colors.black26, onChanged: (val) { setModalState(() => playerLevel = val); setState(() => playerLevel = val); }),
                        Text(_getLevelTitle(playerLevel), style: TextStyle(color: _getLevelColor(playerLevel), fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  
                  // Слайдеры статов
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
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _saveStats, child: const Text("Сохранить", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // --- UI СТРУКТУРА ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("ПРОФИЛЬ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openSettings)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED))) 
        : FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _buildFifaCard(),
                  const SizedBox(height: 30),
                  _buildNeonStatsGrid(),
                  const SizedBox(height: 30),
                  _buildProgressChart(),
                  const SizedBox(height: 30),
                  _buildHistorySection(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
    );
  }

  // --- ВИДЖЕТ: FIFA CARD ---
  Widget _buildFifaCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 520, // Большая карта
      decoration: BoxDecoration(
        gradient: _getLevelGradient(playerLevel),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _getLevelColor(playerLevel).withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 15))],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
      ),
      child: Stack(
        children: [
          // 1. ПАУТИНКА (Radar Chart) - ТЕПЕРЬ ЯРКАЯ И ЗАЛИТАЯ
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: Colors.white.withOpacity(0.25), // 🔥 Заливка белым
                      borderColor: Colors.white, // 🔥 Яркий контур
                      entryRadius: 3,
                      dataEntries: stats.values.map((v) => RadarEntry(value: v)).toList(),
                      borderWidth: 3,
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.white30, width: 2),
                  // 🔥 ПОДПИСИ ПО УГЛАМ (ATK, DEF...)
                  titleTextStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
                  titlePositionPercentageOffset: 0.1, 
                  getTitle: (index, angle) {
                    return RadarChartTitle(text: stats.keys.elementAt(index));
                  },
                  tickCount: 1,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                ),
              ),
            ),
          ),

          // 2. ИНФОРМАЦИЯ ПОВЕРХ ГРАФИКА
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30), // Отступ сверху
                Text(playerLevel.toStringAsFixed(1), style: const TextStyle(fontSize: 85, fontWeight: FontWeight.w900, color: Colors.white, height: 0.9, shadows: [Shadow(color: Colors.black38, blurRadius: 10)])),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: Text(_getLevelTitle(playerLevel), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                ),
                
                GestureDetector(
                  onTap: _uploadPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white60, width: 2)),
                    child: CircleAvatar(
                      radius: 65, 
                      backgroundColor: Colors.white10, 
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null, 
                      child: _avatarUrl == null ? const Icon(Icons.person, size: 70, color: Colors.white54) : null
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(_username.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 5)]), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                
                const SizedBox(height: 30),

                // 🔥 ПОКАЗАТЕЛИ ВНИЗУ КАРТЫ (Разбросаны)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cardStat("PAC", stats['PAC'] ?? 0), 
                      Container(height: 25, width: 1, color: Colors.white30),
                      _cardStat("DRI", stats['DRI'] ?? 0),
                      Container(height: 25, width: 1, color: Colors.white30),
                      _cardStat("SHO", stats['SHO'] ?? 0),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardStat(String label, double val) {
    return Column(children: [
        Text(val.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 3)])),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
    ]);
  }

  // --- WIDGET: НЕОНОВЫЕ БЛОКИ ---
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

  // --- WIDGET: ГРАФИК ПРОГРЕССА ---
  Widget _buildProgressChart() {
    List<FlSpot> spots = [];
    if (_selectedChartPeriod == 0) spots = [const FlSpot(0, 2.9), const FlSpot(1, 2.95), const FlSpot(2, 3.0), FlSpot(3, playerLevel)];
    else if (_selectedChartPeriod == 1) spots = [const FlSpot(0, 1.5), const FlSpot(1, 2.0), const FlSpot(2, 2.2), const FlSpot(3, 2.5), const FlSpot(4, 2.8), FlSpot(5, playerLevel)];
    else spots = [const FlSpot(0, 1.0), const FlSpot(1, 1.5), const FlSpot(2, 2.0), const FlSpot(3, 2.5), const FlSpot(4, 2.9), FlSpot(5, playerLevel)];

    return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("ПРОГРЕСС", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4), child: Row(children: [_chartBtn("1M", 0), const SizedBox(width: 5), _chartBtn("6M", 1), const SizedBox(width: 5), _chartBtn("1Y", 2)])),
        ]),
        const SizedBox(height: 15),
        Container(height: 220, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
          child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
              titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), minX: 0, maxX: spots.last.x, minY: 0, maxY: 7.5,
              lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: _getLevelColor(playerLevel), barWidth: 4, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: true, color: _getLevelColor(playerLevel).withOpacity(0.2)))]
          ), duration: const Duration(milliseconds: 500)),
        ),
    ]);
  }

  Widget _chartBtn(String text, int index) {
    bool active = _selectedChartPeriod == index;
    return GestureDetector(onTap: () => setState(() => _selectedChartPeriod = index), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: active ? const Color(0xFF2F80ED) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))));
  }

  // --- WIDGET: ИСТОРИЯ МАТЧЕЙ ---
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