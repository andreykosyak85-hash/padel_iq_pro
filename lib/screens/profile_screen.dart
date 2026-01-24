import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // Графики
import 'package:image_picker/image_picker.dart'; // Фото
import '../main.dart'; 
import 'schedule_screen.dart'; // Расписание

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Данные профиля
  String username = "Загрузка...";
  double rating = 3.0;
  String? avatarUrl;
  bool isLoading = true;
  bool isUploading = false;

  // Логика переключения графика
  String selectedPeriod = '6M'; // По умолчанию 6 месяцев

  // Статистика
  int totalMatches = 24;
  int winRate = 75;
  int streak = 5;
  int mvpCount = 8;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) {
        setState(() {
          username = data['username'] ?? "Игрок";
          rating = (data['rating'] as num).toDouble();
          avatarUrl = data['avatar_url'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => isUploading = true);
      final imageBytes = await image.readAsBytes();
      final userId = supabase.auth.currentUser!.id;
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('avatars').uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase.from('profiles').update({'avatar_url': url}).eq('id', userId);

      setState(() { avatarUrl = url; isUploading = false; });
    } catch (e) {
      setState(() => isUploading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _openEditScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => const EditProfileScreen())).then((_) => _loadProfile());
  }
  void _openSchedule() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => const ScheduleScreen()));
  }

  // 🔥 ФЕЙКОВЫЕ ДАННЫЕ ДЛЯ ГРАФИКА (ЧТОБЫ ОН МЕНЯЛСЯ)
  List<FlSpot> _getChartData() {
    switch (selectedPeriod) {
      case '1M':
        return const [FlSpot(0, 3.3), FlSpot(1, 3.35), FlSpot(2, 3.2), FlSpot(3, 3.4), FlSpot(4, 3.3), FlSpot(5, 3.4)];
      case 'YTD':
        return const [FlSpot(0, 2.8), FlSpot(1, 2.9), FlSpot(2, 3.0), FlSpot(3, 3.1), FlSpot(4, 3.2), FlSpot(5, 3.4)];
      case '6M':
      default:
        // Основной график
        return const [FlSpot(0, 3.0), FlSpot(1, 3.2), FlSpot(2, 3.15), FlSpot(3, 3.4), FlSpot(4, 3.65), FlSpot(5, 3.9)];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFF0B101F), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0B101F), // Глубокий темный фон
      appBar: AppBar(
        title: const Text("Padel MVP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openEditScreen)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // --- 1. ПРЕМИУМ ШАПКА ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 5))
                ]
              ),
              child: Row(
                children: [
                  // АВАТАР
                  GestureDetector(
                    onTap: _uploadPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 15)],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                              image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover) : null,
                              color: const Color(0xFF0B101F),
                            ),
                            child: avatarUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                          ),
                          if (isUploading) const Positioned.fill(child: CircularProgressIndicator()),
                          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF2F80ED), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 14, color: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // ИМЯ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.5))),
                          child: const Text("AMATEUR", style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        )
                      ],
                    ),
                  ),
                  // РЕЙТИНГ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(rating.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      const Text("RATING", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 2. ВКЛАДКИ ПЕРИОДА (ТЕПЕРЬ РАБОТАЮТ) ---
            Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF161B26), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  _buildTab("1M"),
                  _buildTab("6M"),
                  _buildTab("YTD"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. ГРАФИК (ДИНАМИЧЕСКИЙ) ---
            Container(
              height: 280,
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 10),
                    child: Text("Прогресс ($selectedPeriod)", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5])),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, reservedSize: 30, interval: 1,
                              getTitlesWidget: (value, meta) {
                                const titles = ['ОКТ', 'НОЯ', 'ДЕК', 'ЯНВ', 'ФЕВ', 'МАР'];
                                if (value.toInt() >= 0 && value.toInt() < titles.length) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getChartData(), // <--- ТЕПЕРЬ БЕРЕМ ДАННЫЕ ИЗ ФУНКЦИИ
                            isCurved: true,
                            color: const Color(0xFF3B82F6),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: const Color(0xFF0B101F), strokeWidth: 2, strokeColor: const Color(0xFF3B82F6))),
                            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF3B82F6).withOpacity(0.3), const Color(0xFF3B82F6).withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                          ),
                        ],
                        minX: 0, maxX: 5, minY: 2.5, maxY: 4.5,
                      ),
                      duration: const Duration(milliseconds: 400), // АНИМАЦИЯ СМЕНЫ
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ПЛИТКИ
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.5,
              children: [
                _buildStatCard(Icons.pie_chart, "$winRate%", "Винрейт", Colors.purpleAccent),
                _buildStatCard(Icons.sports_tennis, "$totalMatches", "Матчей", Colors.blueAccent),
                _buildStatCard(Icons.local_fire_department, "$streak Win", "Серия", Colors.orangeAccent),
                _buildStatCard(Icons.star, "$mvpCount раз", "MVP", Colors.yellowAccent),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Расписание и Выход
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openSchedule,
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text("Мое расписание", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
             TextButton(
               onPressed: () async { await supabase.auth.signOut(); if(mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); },
               child: const Text("Выйти", style: TextStyle(color: Colors.redAccent)),
             ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 ИСПРАВЛЕННАЯ ФУНКЦИЯ ВКЛАДОК (ТЕПЕРЬ КЛИКАБЕЛЬНАЯ)
  Widget _buildTab(String text) {
    bool isActive = selectedPeriod == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = text; // Меняем выбранный период
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: isActive 
            ? BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10)]) 
            : null,
          child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, double> stats = {'SMA': 3.0, 'DEF': 3.0, 'TAC': 3.0, 'VOL': 3.0, 'LOB': 3.0, 'PHY': 3.0};
  @override
  void initState() { super.initState(); _loadStats(); }
  Future<void> _loadStats() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase.from('profiles').select().eq('id', userId).single();
    if(mounted && data['stats'] != null) { setState(() { stats = (data['stats'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())); }); }
  }
  Future<void> _save() async {
     final userId = supabase.auth.currentUser!.id;
     await supabase.from('profiles').update({'stats': stats}).eq('id', userId);
     if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Сохранено!"))); Navigator.pop(context); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101F),
      appBar: AppBar(title: const Text("Настройка навыков", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...stats.keys.map((key) => _buildSlider(key)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.all(15)), child: const Text("Сохранить", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
  Widget _buildSlider(String key) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(key, style: const TextStyle(color: Colors.white)), Text(stats[key]!.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF3B82F6)))]),
         Slider(value: stats[key]!, min: 1.0, max: 7.0, divisions: 60, activeColor: const Color(0xFF3B82F6), onChanged: (v) => setState(() => stats[key] = v))
    ]);
  }
}