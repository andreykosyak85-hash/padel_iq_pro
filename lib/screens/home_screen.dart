import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'create_match_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  
  // Неоновые цвета
  final Color _neonOrange = const Color(0xFFFF5500);
  final Color _neonGreen = const Color(0xFFccff00);
  final Color _neonCyan = const Color(0xFF00E5FF);

  String _username = "Игрок";
  String _avatarUrl = "";
  double _level = 0.0;
  bool _isLoading = true;

  // Данные статистики последней игры
  final Map<String, String> _healthStats = {
    'kcal': '680',
    'bpm': '145',
    'dist': '4.5 км',
    'last_score': '6-3, 6-4',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('username, avatar_url, level')
          .eq('id', uid)
          .single();

      if (mounted) {
        setState(() {
          _username = data['username'] ?? "Игрок";
          _avatarUrl = data['avatar_url'] ?? "";
          _level = (data['level'] ?? 0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  LinearGradient _getLevelGradient(double level) {
    if (level >= 4.5) {
      return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else if (level >= 3.5) {
      return const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else if (level >= 2.5) {
      return const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else {
      return const LinearGradient(colors: [Color(0xFF78909C), Color(0xFF455A64)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

  String _getLevelStatus(double level) {
    if (level >= 5.5) return "PRO • Cat 1";
    if (level >= 4.5) return "ADVANCED • Cat 2";
    if (level >= 3.5) return "INTERM.+ • Cat 3";
    if (level >= 2.5) return "INTERM. • Cat 4";
    return "BEGINNER • Cat 5";
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
              child: Image.asset('assets/logo.png', fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_tennis, color: _neonGreen)),
            ),
            const SizedBox(width: 10),
            const Text("PADEL IQ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
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
                // 1. ПРИВЕТСТВИЕ И ПРОФИЛЬ
                SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text("Привет, $_username! 👋", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 5),
                            const Text("Ищем игру?", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Ближайшая игра:", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    const Text("Пока нет записей", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: _neonOrange, minimumSize: const Size(double.infinity, 30)),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMatchScreen())),
                                      child: const Text("Создать", style: TextStyle(color: Colors.white)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _getLevelGradient(_level),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: _getLevelGradient(_level).colors.first.withOpacity(0.4), blurRadius: 10)]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                                  child: _avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(height: 8),
                                Text(_level.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                                  child: Text(_getLevelStatus(_level), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                
                // 2. АКТИВНЫЕ МАТЧИ (ЛЕНТА)
                const Text("Активные матчи рядом 🔥", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMatchCard("Central Club", "19:00", "AndreyK", "Americano", _neonGreen),
                      const SizedBox(width: 15),
                      _buildMatchCard("Padel Arena", "20:30", "Ivan", "Friendly", Colors.blue),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. ИСТОРИЯ ПОСЛЕДНЕЙ ИГРЫ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Последняя игра", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Все игры", style: TextStyle(color: _neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildLastMatchCard(), 

                const SizedBox(height: 20),

                // 4. СТАТИСТИКА ЭТОЙ ИГРЫ (ЗДОРОВЬЕ + ЧАСЫ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Статистика (Last Game)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    // 🔥 Иконка часов на месте!
                    Icon(Icons.watch, color: _neonCyan, size: 20),
                  ],
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildNeonStatCard("ККАЛ", _healthStats['kcal']!, Icons.local_fire_department, _neonOrange),
                      const SizedBox(width: 12),
                      _buildNeonStatCard("ПУЛЬС", _healthStats['bpm']!, Icons.favorite, Colors.redAccent),
                      const SizedBox(width: 12),
                      _buildNeonStatCard("ДИСТАНЦИЯ", _healthStats['dist']!, Icons.directions_run, _neonCyan),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. НОВОСТИ И ОБУЧЕНИЕ (РУССКИЙ ЗАГОЛОВОК)
                const Text("Новости и Обучение", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                _buildNewsCard("Турнир Valencia Open", "Регистрация открыта!", Icons.emoji_events),
                const SizedBox(height: 10),
                _buildNewsCard("Совет тренера", "Как бить смэш x3 (Техника)", Icons.lightbulb),
                
                // 🔥 Большой отступ снизу
                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  // --- ВИДЖЕТЫ ---

  // Карточка Последнего Матча
  Widget _buildLastMatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Вчера • Central Club", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _neonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Text("WIN", style: TextStyle(color: _neonGreen, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null, child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 16) : null),
                  const SizedBox(height: 5),
                  const Text("Вы", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text(_healthStats['last_score']!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  const Text("Competitive", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              Column(
                children: [
                   const CircleAvatar(radius: 18, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white, size: 16)),
                   const SizedBox(height: 5),
                   const Text("Соперник", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
              label: const Text("Анализ игры", style: TextStyle(color: Colors.white, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24)),
            ),
          )
        ],
      ),
    );
  }

  // Карточка Активного матча
  Widget _buildMatchCard(String club, String time, String creator, String type, Color color) {
    return Container(
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
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(club, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Text(creator, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 30)),
            child: const Text("Войти", style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  // Карточка Статистики
  Widget _buildNeonStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, spreadRadius: 0)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Карточка Новости
  Widget _buildNewsCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}