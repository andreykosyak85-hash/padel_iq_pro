import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Доступ к supabase
import 'tournament_screen.dart'; // Импорт экрана турнира

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // --- ЦВЕТА DARK THEME ---
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF161B22);
  final Color _primaryBlue = const Color(0xFF2F80ED);
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  late final Stream<List<Map<String, dynamic>>> _matchesStream;

  @override
  void initState() {
    super.initState();
    _matchesStream = supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: true)
        .map((data) => data.where((m) => m['status'] != 'FINISHED').toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text("Матчи", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: _textWhite)),
        actions: [
          IconButton(icon: Icon(Icons.filter_list, color: _textWhite), onPressed: () {}),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showCreateMatchSheet(context),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _matchesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final matches = snapshot.data!;

          if (matches.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_tennis, size: 60, color: _cardColor),
                const SizedBox(height: 10),
                Text("Нет активных матчей", style: TextStyle(color: _textGrey)),
              ],
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildMatchCard(matches[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    bool isCompetitive = match['is_competitive'] ?? true;
    String type = match['type'] ?? 'Classic';
    int courts = match['courts_count'] ?? 1;
    int maxP = match['max_players'] ?? 4;
    // Берем только подтвержденных для отображения в списке (чтобы не путать с листом ожидания)
    int currentP = match['players_count'] ?? 0; 
    
    double minLvl = (match['level_min'] as num?)?.toDouble() ?? 1.0;
    double maxLvl = (match['level_max'] as num?)?.toDouble() ?? 7.0;

    DateTime date = DateTime.tryParse(match['start_time']) ?? DateTime.now();
    String dateStr = "${date.day}.${date.month}";
    String timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    int price = (match['price'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MatchLobbyScreen(match: match))),
      child: Container(
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка
            Container(
              height: 100,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage("https://images.unsplash.com/photo-1554068865-2414cd956c40?q=80&w=1000&auto=format&fit=crop"), 
                  fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken)
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10, right: 10,
                    child: Row(
                      children: [
                        _badge(_primaryBlue, type),
                        const SizedBox(width: 5),
                        _badge(Colors.black.withOpacity(0.7), "$courts корт(а)"),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            Icon(isCompetitive ? Icons.emoji_events : Icons.handshake, color: isCompetitive ? const Color(0xFFF2C94C) : Colors.white, size: 12),
                          ]),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(match['title'] ?? "Матч", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                      Text("$price€", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: _primaryBlue),
                      const SizedBox(width: 5),
                      Text("$dateStr, $timeStr", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.bar_chart, size: 16, color: _textGrey),
                      const SizedBox(width: 5),
                      Text("${minLvl.toStringAsFixed(1)} - ${maxLvl.toStringAsFixed(1)}", style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxP > 0 ? currentP / maxP : 0,
                      backgroundColor: Colors.white10,
                      color: currentP >= maxP ? Colors.redAccent : const Color(0xFF00E676),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(alignment: Alignment.centerRight, child: Text("$currentP / $maxP игроков", style: TextStyle(color: _textGrey, fontSize: 10))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showCreateMatchSheet(BuildContext context) {
    bool isCompetitive = true;
    String title = "";
    double price = 0;
    final List<String> formats = ['Classic', 'Americano', 'Americano (Team)', 'Americano (Mixed)', 'Mexicano', 'Mexicano (Team)', 'Super Mexicano', 'Winner Court', 'Tournament'];
    String selectedFormat = 'Americano'; 
    int courts = 1;
    RangeValues levelRange = const RangeValues(1.0, 7.0);
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            
            Future<void> pickDateTime() async {
              final DateTime? date = await showDatePicker(
                context: context, initialDate: selectedDateTime, firstDate: DateTime.now(), lastDate: DateTime(2100),
                builder: (context, child) => Theme(data: ThemeData.dark(), child: child!)
              );
              if (date == null) return;
              final TimeOfDay? time = await showTimePicker(
                context: context, initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                builder: (context, child) => Theme(data: ThemeData.dark(), child: child!)
              );
              if (time == null) return;
              setSheetState(() => selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, color: Colors.grey[600], margin: const EdgeInsets.only(bottom: 20))),
                  Center(child: Text("Создать матч", style: TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  
                  Row(children: [
                    Expanded(child: GestureDetector(onTap: () => setSheetState(() => isCompetitive = true), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isCompetitive ? _primaryBlue.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isCompetitive ? _primaryBlue : Colors.white10)), child: Center(child: Text("Ranked", style: TextStyle(color: isCompetitive ? _primaryBlue : Colors.grey, fontWeight: FontWeight.bold)))))), 
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(onTap: () => setSheetState(() => isCompetitive = false), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !isCompetitive ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: !isCompetitive ? Colors.white : Colors.white10)), child: Center(child: Text("Friendly", style: TextStyle(color: !isCompetitive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)))))),
                  ]),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Формат", style: TextStyle(color: _textGrey, fontSize: 12)), const SizedBox(height: 5),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedFormat, dropdownColor: _cardColor, style: TextStyle(color: _textWhite, fontSize: 14), isExpanded: true, items: formats.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setSheetState(() => selectedFormat = val!)))),
                          ]),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Корты", style: TextStyle(color: _textGrey, fontSize: 12)), const SizedBox(height: 5),
                            Container(height: 48, decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [InkWell(onTap: () => setSheetState(() { if (courts > 1) courts--; }), child: Icon(Icons.remove, color: _textGrey, size: 20)), Text("$courts", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 16)), InkWell(onTap: () => setSheetState(() => courts++), child: Icon(Icons.add, color: _primaryBlue, size: 20))])),
                          ]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Уровень (NTRP)", style: TextStyle(color: _textGrey, fontSize: 12)), Text("${levelRange.start.toStringAsFixed(1)} - ${levelRange.end.toStringAsFixed(1)}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold))]),
                  RangeSlider(values: levelRange, min: 1.0, max: 7.0, divisions: 12, activeColor: _primaryBlue, inactiveColor: _bgDark, labels: RangeLabels(levelRange.start.toStringAsFixed(1), levelRange.end.toStringAsFixed(1)), onChanged: (val) => setSheetState(() => levelRange = val)),

                  const SizedBox(height: 10),
                  Text("Дата и время", style: TextStyle(color: _textGrey, fontSize: 12)), const SizedBox(height: 5),
                  GestureDetector(
                    onTap: pickDateTime,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.calendar_month, color: _primaryBlue), const SizedBox(width: 10), Text("${selectedDateTime.day}.${selectedDateTime.month}.${selectedDateTime.year}  |  ${selectedDateTime.hour.toString().padLeft(2,'0')}:${selectedDateTime.minute.toString().padLeft(2,'0')}", style: TextStyle(color: _textWhite, fontSize: 16, fontWeight: FontWeight.bold)), const Spacer(), Icon(Icons.edit, color: _textGrey, size: 16)])),
                  ),

                  const SizedBox(height: 15),
                  Row(children: [
                      Expanded(flex: 2, child: TextField(style: TextStyle(color: _textWhite), decoration: InputDecoration(labelText: "Название", labelStyle: TextStyle(color: _textGrey), filled: true, fillColor: _bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (v) => title = v)),
                      const SizedBox(width: 10),
                      Expanded(flex: 1, child: TextField(style: TextStyle(color: _textWhite), decoration: InputDecoration(labelText: "Цена (€)", labelStyle: TextStyle(color: _textGrey), filled: true, fillColor: _bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.number, onChanged: (v) => price = double.tryParse(v) ?? 0)),
                    ]),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: isLoading ? null : () async {
                        setSheetState(() => isLoading = true);
                        try {
                          final uid = supabase.auth.currentUser?.id;
                          if (uid == null) throw "Нужен вход";
                          await supabase.from('matches').insert({
                            'creator_id': uid, 'title': title.isEmpty ? "Match" : title, 'is_competitive': isCompetitive, 'price': price, 'type': selectedFormat, 'courts_count': courts, 'level_min': levelRange.start, 'level_max': levelRange.end, 'players_count': 0, 'max_players': courts * 4, 'status': 'OPEN', 'start_time': selectedDateTime.toIso8601String(),
                          });
                          if(context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Матч создан!"), backgroundColor: Colors.green)); }
                        } catch(e) {
                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red));
                        } finally { if(mounted) setSheetState(() => isLoading = false); }
                      },
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Создать", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- ЛОББИ С WAITLIST, УДАЛЕНИЕМ И КОРТАМИ ---
class MatchLobbyScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  const MatchLobbyScreen({super.key, required this.match});
  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF161B22);
  final Color _primaryBlue = const Color(0xFF2F80ED);
  
  List<Map<String, dynamic>> confirmedPlayers = [];
  List<Map<String, dynamic>> waitingList = [];
  bool isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkCreator();
    _loadParticipants();
  }

  void _checkCreator() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == widget.match['creator_id']) setState(() => isCreator = true);
  }

  Future<void> _loadParticipants() async {
    final res = await supabase.from('participants').select('user_id, status, profiles(username, level, avatar_url)').eq('match_id', widget.match['id']);
    if(mounted) {
      setState(() {
        // Разделяем на Основу и Лист Ожидания
        var all = List<Map<String, dynamic>>.from(res);
        confirmedPlayers = all.where((p) => p['status'] == 'CONFIRMED').toList();
        waitingList = all.where((p) => p['status'] == 'WAITING').toList();
      });
      // Обновляем счетчик ТОЛЬКО подтвержденных
      await supabase.from('matches').update({'players_count': confirmedPlayers.length}).eq('id', widget.match['id']);
    }
  }

  Future<void> _joinSlot() async {
    try {
      final uid = supabase.auth.currentUser!.id;
      // Проверяем где игрок (в основе или в листе)
      final inConfirmed = confirmedPlayers.any((p) => p['user_id'] == uid);
      final inWaiting = waitingList.any((p) => p['user_id'] == uid);

      if (inConfirmed || inWaiting) {
        // Если уже где-то есть - удаляем (выход)
        await supabase.from('participants').delete().eq('match_id', widget.match['id']).eq('user_id', uid);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Вы покинули игру")));
      } else {
        // Если не записан - пытаемся войти
        int maxP = widget.match['max_players'] ?? 4;
        String status = 'CONFIRMED';
        
        // Если мест нет - идем в WAITING
        if (confirmedPlayers.length >= maxP) {
          status = 'WAITING';
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Мест нет. Вы добавлены в Лист Ожидания."), backgroundColor: Colors.orange));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Вы записаны!"), backgroundColor: Colors.green));
        }

        await supabase.from('participants').insert({'match_id': widget.match['id'], 'user_id': uid, 'status': status});
      }
      _loadParticipants();
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text("Удалить игру?", style: TextStyle(color: Colors.white)),
        content: const Text("Все участники будут удалены.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Удалить", style: TextStyle(color: Colors.redAccent))),
        ],
      )
    );

    if (confirm == true) {
      try {
        await supabase.from('participants').delete().eq('match_id', widget.match['id']);
        await supabase.from('matches').delete().eq('id', widget.match['id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
      }
    }
  }

  void _startGame() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => TournamentScreen(
      title: widget.match['title'],
      matchId: widget.match['id'],
      courts: widget.match['courts_count'] ?? 1,
      gameType: widget.match['type'] ?? 'Classic',
    )));
  }

  @override
  Widget build(BuildContext context) {
    bool isCompetitive = widget.match['is_competitive'] ?? true;
    int courts = widget.match['courts_count'] ?? 1;
    int maxPlayers = widget.match['max_players'] ?? (courts * 4);
    bool isFull = confirmedPlayers.length >= maxPlayers;

    final uid = supabase.auth.currentUser?.id;
    bool inConfirmed = confirmedPlayers.any((p) => p['user_id'] == uid);
    bool inWaiting = waitingList.any((p) => p['user_id'] == uid);

    // Логика кнопки и цвета
    String btnText = "Записаться";
    Color btnColor = _primaryBlue;

    if (inConfirmed) {
      btnText = "Выйти из игры";
      btnColor = Colors.redAccent;
    } else if (inWaiting) {
      btnText = "Покинуть очередь";
      btnColor = Colors.orange;
    } else if (isFull) {
      btnText = "Встать в очередь"; // Waitlist
      btnColor = const Color(0xFFF2C94C); // Золотой/Оранжевый
    }

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark, elevation: 0, leading: const BackButton(color: Colors.white), 
        title: Text(widget.match['title'] ?? "Матч", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [if (isCreator) IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: _deleteMatch)]
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_tabBtn("Info", false), const SizedBox(width: 10), _tabBtn("Schedule", true), const SizedBox(width: 10), _tabBtn("Statistics", false)])),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(15), margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(isCompetitive ? Icons.emoji_events : Icons.tag_faces, color: isCompetitive ? const Color(0xFFF2C94C) : Colors.blue), const SizedBox(width: 10), Expanded(child: Text(isCompetitive ? "Рейтинговый матч" : "Дружеский матч", style: const TextStyle(color: Colors.white70)))])),
            const SizedBox(height: 30),

            // 🔥 КОРТЫ 🔥
            Column(
              children: List.generate(courts, (courtIndex) {
                int baseIndex = courtIndex * 4;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                  child: Column(
                    children: [
                      Text("КОРТ ${courtIndex + 1}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [_playerSlot(baseIndex), const SizedBox(height: 20), _playerSlot(baseIndex + 1)]),
                          SizedBox(height: 150, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 2, height: 40, color: Colors.white10), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _cardColor, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)), child: const Text("VS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))), Container(width: 2, height: 40, color: Colors.white10)])),
                          Column(children: [_playerSlot(baseIndex + 2), const SizedBox(height: 20), _playerSlot(baseIndex + 3)]),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            // 🔥 ЛИСТ ОЖИДАНИЯ (ПОЯВЛЯЕТСЯ ЕСЛИ КТО-ТО ЖДЕТ) 🔥
            if (waitingList.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Text("Лист ожидания:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: waitingList.length,
                  itemBuilder: (context, index) {
                    final p = waitingList[index]['profiles'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          CircleAvatar(radius: 25, backgroundImage: NetworkImage(p['avatar_url'] ?? "https://i.pravatar.cc/150"), backgroundColor: Colors.orange.withOpacity(0.2)),
                          const SizedBox(height: 5),
                          Text(p['username'] ?? "Wait", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // КНОПКИ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: SizedBox(height: 55, child: ElevatedButton(onPressed: _joinSlot, style: ElevatedButton.styleFrom(backgroundColor: btnColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))))),
                  if (isCreator) ...[const SizedBox(width: 10), Expanded(child: SizedBox(height: 55, child: ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("СТАРТ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))))]
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String text, bool isActive) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isActive ? _primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(8), border: isActive ? null : Border.all(color: Colors.white24)), child: Center(child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontWeight: FontWeight.bold)))));
  }

  Widget _playerSlot(int index) {
    Map<String, dynamic>? player;
    // Берем только из ПОДТВЕРЖДЕННЫХ
    if (index < confirmedPlayers.length) player = confirmedPlayers[index];
    
    if (player != null) {
      final profile = player['profiles'];
      return Column(children: [CircleAvatar(radius: 35, backgroundColor: _cardColor, backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null, child: profile['avatar_url'] == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null), const SizedBox(height: 5), Text(profile['username'] ?? "Игрок", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]);
    } else {
      return GestureDetector(onTap: _joinSlot, child: Column(children: [Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 2)), child: const Icon(Icons.add, color: Colors.white24, size: 30)), const SizedBox(height: 5), const Text("Добавить", style: TextStyle(color: Colors.white24))]));
    }
  }
}