import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 
import 'chat_screen.dart';
import 'tournament_screen.dart';
import 'profile_screen.dart'; 

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // --- ДАННЫЕ ПРОФИЛЯ ---
  double myRating = 3.0;
  String myName = "Загрузка...";
  String? myAvatarUrl;
  
  Map<String, dynamic> myStats = {
    'SMA': 3.0, 'DEF': 3.0, 'TAC': 3.0, 
    'VOL': 3.0, 'LOB': 3.0, 'PHY': 3.0
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      
      if (mounted) {
        setState(() {
          myRating = (data['rating'] as num).toDouble();
          myName = data['username'] ?? "Игрок";
          myAvatarUrl = data['avatar_url'];
          if (data['stats'] != null) {
            myStats = data['stats'];
          }
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки профиля: $e");
    }
  }

  // --- ЛОГИКА СОЗДАНИЯ МАТЧА ---
  Future<void> _createMatchInCloud({
    required String title,
    required String type,
    required int courts,
    required double minRating,
    required double maxRating,
    required bool isPublic,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // 1. Создаем матч
      final matchResponse = await supabase.from('matches').insert({
        'creator_id': userId,
        'title': title,
        'type': type,
        'status': 'OPEN',
        'courts_count': courts,
        'min_rating': minRating,
        'max_rating': maxRating,
        'is_public': isPublic,
        'start_time': DateTime.now().add(const Duration(days: 1)).toIso8601String(), 
      }).select().single();

      // 2. Автор сразу записывается
      await supabase.from('participants').insert({
        'match_id': matchResponse['id'],
        'user_id': userId,
        'status': 'CONFIRMED'
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Игра создана!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка создания: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // СТРИМ МАТЧЕЙ
    final Stream<List<Map<String, dynamic>>> matchesStream = supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Темный фон
      
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMatchDialog,
        backgroundColor: const Color(0xFF2F80ED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF2F80ED),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 2) {
             Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()))
             .then((_) => _loadUserProfile());
          }
          if (index == 1) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Бронь скоро!")));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Матчи'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Бронь'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPremiumCard(), 
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft, child: Text("Ближайшие игры (LIVE)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: matchesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(20), child: Text("Ошибка: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                
                final matches = snapshot.data!;
                if (matches.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("Нет игр", style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matches.length,
                  itemBuilder: (context, index) => MatchCardWidget(
                    key: ValueKey(matches[index]['id']), // Важно для обновления состояния
                    match: matches[index]
                  ), 
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())).then((_) => _loadUserProfile()),
      child: Center(
        child: Container(
          width: 320, height: 480,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6EC1E4), Color(0xFF2F80ED)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
          ),
          child: Stack(
            children: [
              Positioned(top: 40, left: 30, child: Text(myRating.toStringAsFixed(2), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.black87))),
              if (myAvatarUrl == null) const Positioned(top: 140, left: 0, right: 0, child: Center(child: Icon(Icons.camera_alt_outlined, size: 60, color: Colors.black12))),
              if (myAvatarUrl != null) Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.network(myAvatarUrl!, fit: BoxFit.cover, color: Colors.black.withOpacity(0.1), colorBlendMode: BlendMode.darken))),
              Positioned(bottom: 140, left: 0, right: 0, child: Center(child: Text(myName.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)))),
              Positioned(bottom: 40, left: 30, right: 30, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_statRow("VOL", myStats['VOL']), _statRow("LOB", myStats['LOB']), _statRow("PHY", myStats['PHY']),]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_statRow("SMA", myStats['SMA'], alignRight: true), _statRow("DEF", myStats['DEF'], alignRight: true), _statRow("TAC", myStats['TAC'], alignRight: true),]),
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, dynamic val, {bool alignRight = false}) {
    double value = (val is num) ? val.toDouble() : 3.0;
    List<Widget> children = [Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54))];
    if (alignRight) children = children.reversed.toList();
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: children));
  }

  // 🔥 ДИАЛОГ СОЗДАНИЯ ИГРЫ 🔥
  void _showCreateMatchDialog() {
    String title = 'Игра ${DateTime.now().day}.${DateTime.now().month}';
    String selectedFormat = 'Americano'; 
    int selectedCourts = 1;
    int maxPlayers = 4;
    RangeValues currentRange = const RangeValues(1.0, 7.0);
    bool isPublic = true;

    final List<String> gameTypes = [
      'Match (Classic)', 'Americano', 'Americano (Team)', 'Americano (Mixed)',
      'Mexicano', 'Mexicano (Team)', 'Super Mexicano', 'Winner Court', 'Tournament (Cup)',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (selectedFormat == 'Match (Classic)') maxPlayers = 4;

            return AlertDialog(
              backgroundColor: const Color(0xFF161B22), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Создать игру', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Название', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF0D1117)),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFormat,
                      dropdownColor: const Color(0xFF161B22),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Формат", labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF0D1117)),
                      items: gameTypes.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setDialogState(() {
                        selectedFormat = val!;
                        if (selectedFormat == 'Match (Classic)') { selectedCourts = 1; maxPlayers = 4; } 
                        else { maxPlayers = selectedCourts * 4; }
                      }),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Корты:", style: TextStyle(color: Colors.white, fontSize: 16)),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove_circle, color: Color(0xFF2F80ED)), onPressed: () => setDialogState(() { if (selectedCourts > 1) { selectedCourts--; maxPlayers = selectedCourts * 4; } })),
                                  Text('$selectedCourts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF2F80ED)), onPressed: () => setDialogState(() { selectedCourts++; maxPlayers = selectedCourts * 4; })),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text("Участников:", style: TextStyle(color: Colors.grey)),
                              Text("$maxPlayers", style: const TextStyle(color: Color(0xFF2F80ED), fontWeight: FontWeight.bold, fontSize: 16)),
                            ])
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: currentRange, min: 1.0, max: 7.0, divisions: 12, activeColor: const Color(0xFF2F80ED),
                      labels: RangeLabels(currentRange.start.toStringAsFixed(1), currentRange.end.toStringAsFixed(1)),
                      onChanged: (val) => setDialogState(() => currentRange = val),
                    ),
                    SwitchListTile(title: const Text("Публичная", style: TextStyle(color: Colors.white)), value: isPublic, activeThumbColor: const Color(0xFF2F80ED), onChanged: (val) => setDialogState(() => isPublic = val))
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    _createMatchInCloud(title: title, type: selectedFormat, courts: selectedCourts, minRating: currentRange.start, maxRating: currentRange.end, isPublic: isPublic);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED)),
                  child: const Text('Создать', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// 🔥 ИСПРАВЛЕННАЯ КАРТОЧКА МАТЧА 🔥
class MatchCardWidget extends StatefulWidget {
  final Map<String, dynamic> match;
  const MatchCardWidget({super.key, required this.match});

  @override
  State<MatchCardWidget> createState() => _MatchCardWidgetState();
}

class _MatchCardWidgetState extends State<MatchCardWidget> {
  String? myStatus; 
  bool isCreator = false;
  int participantsCount = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void didUpdateWidget(covariant MatchCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match != widget.match) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final userId = supabase.auth.currentUser!.id;
    final matchId = widget.match['id'];
    
    if (widget.match['creator_id'] == userId) {
      if(mounted) setState(() => isCreator = true);
    }

    final response = await supabase.from('participants').select().eq('match_id', matchId);
    final participants = response as List;

    if(mounted) {
      setState(() {
        participantsCount = participants.where((p) => p['status'] == 'CONFIRMED').length;
        // Ищем себя в списке для обновления кнопки
        try {
          final me = participants.firstWhere((p) => p['user_id'] == userId);
          myStatus = me['status'];
        } catch (e) {
          myStatus = null; // Не найден - значит не записан
        }
      });
    }
  }

  // ВХОД / ВЫХОД
  Future<void> _handleJoinOrLeave() async {
    setState(() => isLoading = true);
    final userId = supabase.auth.currentUser!.id;
    final matchId = widget.match['id'];
    int maxPlayers = (widget.match['courts_count'] ?? 1) * 4;

    try {
      if (myStatus == 'CONFIRMED' || myStatus == 'WAITING') {
        // --- ВЫХОД ---
        final startTime = DateTime.parse(widget.match['start_time']);
        final difference = startTime.difference(DateTime.now()).inHours;

        if (difference < 5) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Менее 5 часов. Отмена через админа."), backgroundColor: Colors.red));
          setState(() => isLoading = false);
          return;
        }

        await supabase.from('participants').delete().eq('match_id', matchId).eq('user_id', userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Вы вышли.")));
        
        // Сбрасываем статус локально сразу, чтобы кнопка обновилась
        setState(() { myStatus = null; });
        
      } else {
        // --- ВХОД ---
        String status = participantsCount >= maxPlayers ? 'WAITING' : 'CONFIRMED';
        
        try {
          await supabase.from('participants').insert({'match_id': matchId, 'user_id': userId, 'status': status});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'WAITING' ? "В листе ожидания" : "Вы записаны!")));
          setState(() { myStatus = status; });
        } on PostgrestException catch (e) {
          // 🔥 ИСПРАВЛЕНИЕ: ЛОВИМ ОШИБКУ "УЖЕ ЗАПИСАН" (23505)
          if (e.code == '23505') {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Вы уже записаны на эту игру"), backgroundColor: Colors.green));
             _checkStatus(); // Просто обновляем статус
          } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: ${e.message}"), backgroundColor: Colors.red));
          }
        }
      }
      await _checkStatus();
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMatch() async {
    try {
      final matchId = widget.match['id'];
      await supabase.from('participants').delete().eq('match_id', matchId);
      await supabase.from('matches').delete().eq('id', matchId);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Матч удален")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _startGame() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => TournamentScreen(
      title: widget.match['title'], 
      matchId: widget.match['id'], 
      courts: widget.match['courts_count'] ?? 1,
      gameType: widget.match['type'] ?? 'Americano',
    )));
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 РАСЧЕТ ИГРОКОВ ПРЯМО ТУТ
    int courts = widget.match['courts_count'] ?? 1;
    int maxPlayers = courts * 4;
    bool isFull = participantsCount >= maxPlayers;

    String btnText = "Записаться";
    Color btnColor = const Color(0xFF2F80ED); // Синий

    if (myStatus == 'CONFIRMED') {
      btnText = "Отменить запись";
      btnColor = Colors.redAccent;
    } else if (myStatus == 'WAITING') {
      btnText = "Покинуть очередь";
      btnColor = Colors.orange;
    } else if (isFull) {
      btnText = "В лист ожидания";
      btnColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.match['title'] ?? 'Игра', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${widget.match['type']} • Корт: $courts", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      "Игроков: $participantsCount / $maxPlayers ${isFull ? '(FULL)' : ''}", 
                      style: TextStyle(color: isFull ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              if (isCreator)
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: _deleteMatch)
              else
                IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(chatTitle: widget.match['title']))))
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _handleJoinOrLeave(),
                  style: ElevatedButton.styleFrom(backgroundColor: btnColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isLoading ? "..." : btnText, style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              if (isCreator)
                 Expanded(
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("СТАРТ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              else 
                 Expanded(
                  child: OutlinedButton(
                    onPressed: _startGame, 
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Сетка", style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}