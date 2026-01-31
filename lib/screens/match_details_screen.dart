import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'match_control_screen.dart'; // Убедись, что этот файл существует

class MatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? match;
  final String? matchId;

  const MatchDetailsScreen({
    super.key,
    this.match,
    this.matchId,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  late Future<Map<String, dynamic>> _matchFuture;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) {
      _matchFuture = _loadMatch(widget.matchId!);
    } else {
      _matchFuture = Future.value(widget.match!);
    }
  }

  Future<Map<String, dynamic>> _loadMatch(String matchId) async {
    final response = await _supabase
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();
    return response as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _matchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1117),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFccff00)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Text("Ошибка"),
            ),
            body: Center(
              child: Text(
                "Ошибка загрузки: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final match = snapshot.data!;
        return _buildMatchDetails(match);
      },
    );
  }

  Widget _buildMatchDetails(Map<String, dynamic> match) {
    // --- ПАРСИНГ ДАННЫХ ---

    // 1. Время и Дата
    String timeStr = "???";
    String dateStr = "???";

    if (match['start_time'] != null) {
      final dateTime = DateTime.tryParse(match['start_time'].toString());
      if (dateTime != null) {
        timeStr =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
        dateStr = "${dateTime.day}.${dateTime.month}.${dateTime.year}";
      }
    } else {
      timeStr = match['time']?.toString() ?? "???";
      dateStr = match['date']?.toString() ?? "???";
    }

    // 2. Локация (Клуб)
    String location = "Клуб не указан";
    if (match['clubs'] != null && match['clubs']['name'] != null) {
      location = match['clubs']['name'];
    } else if (match['location'] != null) {
      location = match['location'];
    }

    // 3. Остальное
    final type = match['type'] ?? 'Match';
    final level = match['level_min']?.toString() ?? '-';
    
    final price = match['price_per_person'] != null
        ? "${match['price_per_person']}€"
        : "20€";
        
    final court = match['court_name'] ?? "Корт №3 (Indoor)";

    // --- ЦВЕТА ---
    const bgDark = Color(0xFF0D1117);
    const cardColor = Color(0xFF1C1C1E);
    const neonGreen = Color(0xFFccff00);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Детали матча",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. КАРТОЧКА С ОСНОВНОЙ ИНФОЙ
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white10,
                    backgroundImage: const AssetImage('assets/logo.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(type,
                      style: const TextStyle(
                          color: neonGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text("$timeStr | $dateStr",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(location,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. 🔥 КНОПКА "ПЕРЕЙТИ К ИГРЕ" (ТЕПЕРЬ НА СВОЕМ МЕСТЕ)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFccff00), // Неон
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchControlScreen(match: match),
                    ),
                  );
                },
                child: const Text("ПЕРЕЙТИ К ИГРЕ ⏱️",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),

            // 3. ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ
            const Text("Информация",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _infoRow("Уровень", "Cat $level"),
            const Divider(color: Colors.white10),
            _infoRow("Цена", "$price с человека"),
            const Divider(color: Colors.white10),
            _infoRow("Корт", court),

            const Spacer(),

            // 4. КНОПКИ ВНИЗУ (НАЗАД / ЧАТ)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Назад",
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Логика чата
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Чат игры",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}