import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'tournament_screen.dart';
import 'match_control_screen.dart';
import 'dart:async';

class MatchesScreen extends StatefulWidget {
  final int initialIndex;
  const MatchesScreen({super.key, this.initialIndex = 0});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _primaryBlue = const Color(0xFF007AFF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF8E8E93);

  Stream<List<Map<String, dynamic>>>? _matchesStream;
  List<int> _myGroupIds = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _initStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initStream() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      final membersData = await supabase.from('group_members').select('group_id').eq('user_id', uid);
      if (mounted) {
        setState(() {
          _myGroupIds = List<int>.from(membersData.map((e) => e['group_id']));
        });
      }
    }
    // 🔥 Сортируем от СТАРЫХ к НОВЫМ (ascending: true)
    // Это важно, чтобы в "Поиске" ближайшие игры были сверху.
    // А в "Истории" мы этот список перевернем (reversed).
    final stream = supabase.from('matches').stream(primaryKey: ['id']).order('start_time', ascending: true);
    if (mounted) setState(() => _matchesStream = stream);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text("Матчи", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: _textWhite, fontFamily: '.SF Pro Display')),
        actions: [IconButton(icon: Icon(Icons.filter_list, color: _primaryBlue), onPressed: () {})],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primaryBlue,
          labelColor: _primaryBlue,
          unselectedLabelColor: _textGrey,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [Tab(text: "Поиск"), Tab(text: "Мои"), Tab(text: "История")],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        shape: const CircleBorder(),
        elevation: 10,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showCreateMatchSheet(context),
      ),
      body: _matchesStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _matchesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final allMatches = snapshot.data ?? [];
                final uid = supabase.auth.currentUser?.id;
                final now = DateTime.now();

                // 1. История
                final historyList = allMatches.where((m) {
                  DateTime date;
                  try { date = DateTime.parse(m['start_time'].toString()); } catch(e) { date = now; }
                  final isFinished = m['status'] == 'FINISHED';
                  final isOld = date.add(const Duration(hours: 5)).isBefore(now);
                  final matchGroupId = m['group_id'];
                  if (matchGroupId != null && !_myGroupIds.contains(matchGroupId)) return false;
                  return isFinished || isOld;
                }).toList();

                // 2. Активные
                final activeList = allMatches.where((m) {
                  if (historyList.contains(m)) return false;
                  final matchGroupId = m['group_id'];
                  if (matchGroupId != null && !_myGroupIds.contains(matchGroupId)) return false;
                  return true;
                }).toList();

                // 3. Мои
                final myList = activeList.where((m) => m['creator_id'] == uid).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Поиск: Ближайшие сверху (стандартный порядок)
                    _buildList(activeList, "Нет активных игр"),
                    
                    // Мои: Сначала новые (переворачиваем)
                    _buildList(myList.reversed.toList(), "Вы не создали игр"),
                    
                    // 🔥 История: Сначала НЕДАВНИЕ (переворачиваем, чтобы старые ушли вниз)
                    _buildList(historyList.reversed.toList(), "История пуста", isHistory: true),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> matches, String emptyText, {bool isHistory = false}) {
    if (matches.isEmpty) return Center(child: Text(emptyText, style: TextStyle(color: _textGrey, fontSize: 16)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (c, i) => const SizedBox(height: 20),
      itemBuilder: (context, index) => MatchCardItem(match: matches[index], isHistory: isHistory),
    );
  }

  // --- МЕНЮ СОЗДАНИЯ ---
  void _showCreateMatchSheet(BuildContext context) {
    bool isCompetitive = true;
    String title = "";
    String customLocation = "";
    double price = 0;
    int courts = 1;
    RangeValues _currentRangeValues = const RangeValues(0.0, 7.0);

    final List<String> formats = ['Classic', 'Americano', 'Americano (Team)', 'Mexicano', 'Mexicano (Team)', 'Winner Court', 'Tournament'];
    String selectedFormat = 'Classic';
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    String? selectedClubId;
    List<Map<String, dynamic>> clubsList = [];
    String? selectedGroupId;
    List<Map<String, dynamic>> myGroupsList = [];
    
    final BoxDecoration neonDecoration = BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _primaryBlue.withOpacity(0.5), width: 1),
      boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.15), blurRadius: 8, spreadRadius: 0)]
    );

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          if (clubsList.isEmpty) {
             Future.wait([
               supabase.from('clubs').select('id, name'),
               supabase.from('groups').select('id, name').filter('id', 'in', _myGroupIds.isEmpty ? [-1] : _myGroupIds)
             ]).then((res) {
               if (context.mounted) {
                 setSheetState(() {
                   clubsList = List<Map<String, dynamic>>.from(res[0] as List);
                   myGroupsList = List<Map<String, dynamic>>.from(res[1] as List);
                 });
               }
             });
          }
          
          Future<void> pickDateTime() async {
              final date = await showDatePicker(context: context, initialDate: selectedDateTime, firstDate: DateTime.now(), lastDate: DateTime(2100), builder: (c, child) => Theme(data: ThemeData.dark(), child: child!));
              if (date == null) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDateTime), builder: (c, child) => Theme(data: ThemeData.dark(), child: child!));
              if (time == null) return;
              setSheetState(() => selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, color: _primaryBlue.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 20))),
                Center(child: Text("Новая игра", style: TextStyle(color: _textWhite, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: _primaryBlue, blurRadius: 10)]))),
                const SizedBox(height: 25),
                
                _input("Название (обязательно)", (v) => title = v, neonDecoration),
                const SizedBox(height: 15),

                _label("Видимость"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12), decoration: neonDecoration,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                        value: selectedGroupId, dropdownColor: const Color(0xFF1C1C1E), style: const TextStyle(color: Colors.white), isExpanded: true, icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
                        items: [const DropdownMenuItem(value: null, child: Text("🌍 Для всех")), ...myGroupsList.map((g) => DropdownMenuItem(value: g['id'].toString(), child: Text("🔒 ${g['name']}")))],
                        onChanged: (v) => setSheetState(() => selectedGroupId = v)),
                  ),
                ),
                const SizedBox(height: 15),

                _label("Клуб"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12), decoration: neonDecoration,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedClubId, dropdownColor: const Color(0xFF1C1C1E), style: const TextStyle(color: Colors.white), isExpanded: true, hint: const Text("Выберите клуб", style: TextStyle(color: Colors.grey)), icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
                      items: clubsList.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                      onChanged: (v) => setSheetState(() => selectedClubId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _input("ИЛИ Свой клуб / Адрес", (v) => customLocation = v, neonDecoration),
                const SizedBox(height: 15),

                _label("Формат"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12), decoration: neonDecoration,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                        value: selectedFormat, dropdownColor: const Color(0xFF1C1C1E), style: const TextStyle(color: Colors.white), isExpanded: true, icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
                        items: formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (v) => setSheetState(() => selectedFormat = v!)),
                  ),
                ),
                const SizedBox(height: 15),

                Row(children: [
                  Expanded(child: _input("Цена €", (v) => price = double.tryParse(v) ?? 0, neonDecoration, isNum: true)),
                  const SizedBox(width: 15),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Корты", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    Container(
                      decoration: neonDecoration,
                      child: Row(children: [
                        IconButton(icon: Icon(Icons.remove, color: _primaryBlue), onPressed: () => setSheetState(() { if (courts > 1) courts--; })),
                        Text("$courts", style: TextStyle(color: _textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: Icon(Icons.add, color: _primaryBlue), onPressed: () => setSheetState(() => courts++)),
                      ]),
                    )
                  ])
                ]),
                Align(alignment: Alignment.centerRight, child: Padding(
                  padding: const EdgeInsets.only(top: 5, right: 5),
                  child: Text("Игроков: ${courts * 4}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, shadows: [Shadow(color: _primaryBlue, blurRadius: 5)])),
                )),
                
                const SizedBox(height: 15),
                _label("Уровень игроков"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: neonDecoration,
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Min: ${_currentRangeValues.start.toStringAsFixed(1)}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                        Text("Max: ${_currentRangeValues.end.toStringAsFixed(1)}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                    ]),
                    RangeSlider(
                      values: _currentRangeValues, min: 0.0, max: 7.0, divisions: 14, activeColor: _primaryBlue, inactiveColor: _primaryBlue.withOpacity(0.3),
                      labels: RangeLabels(_currentRangeValues.start.toStringAsFixed(1), _currentRangeValues.end.toStringAsFixed(1)),
                      onChanged: (RangeValues values) => setSheetState(() => _currentRangeValues = values),
                    ),
                  ]),
                ),

                const SizedBox(height: 15),
                _label("Дата"),
                GestureDetector(onTap: pickDateTime, child: Container(padding: const EdgeInsets.all(15), decoration: neonDecoration, child: Row(children: [Icon(Icons.calendar_month, color: _primaryBlue), const SizedBox(width: 10), Text("${selectedDateTime.day}.${selectedDateTime.month} | ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2,'0')}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Spacer(), Icon(Icons.edit, color: _primaryBlue, size: 16)]))),
                const SizedBox(height: 25),
                
                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () async {
                    if (title.isEmpty) return;
                    try {
                      await supabase.from('matches').insert({
                        'creator_id': supabase.auth.currentUser!.id, 'title': title, 'club_id': selectedClubId != null ? int.parse(selectedClubId!) : null,
                        'location': customLocation.isNotEmpty ? customLocation : null, 'price': price, 'type': selectedFormat, 'courts_count': courts, 'max_players': courts * 4,
                        'group_id': selectedGroupId != null ? int.parse(selectedGroupId!) : null,
                        'is_competitive': isCompetitive, 'status': 'OPEN', 'start_time': selectedDateTime.toIso8601String(),
                        'players_count': 0,
                        'level_min': _currentRangeValues.start,
                        'level_max': _currentRangeValues.end,
                      });
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
                  },
                  child: const Text("СОЗДАТЬ ИГРУ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                )),
                const SizedBox(height: 10),
              ]),
            ),
          );
        });
      },
    );
  }

  Widget _label(String text) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 5, left: 5), child: Text(text, style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold))));
  Widget _input(String label, Function(String) onChange, BoxDecoration decoration, {bool isNum = false}) => Container(decoration: decoration, child: TextField(style: const TextStyle(color: Colors.white), keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: _textGrey), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), border: InputBorder.none), onChanged: onChange));
}

// -------------------------------------------------------------
// 🔥 КАРТОЧКА МАТЧА
// -------------------------------------------------------------
class MatchCardItem extends StatefulWidget {
  final Map<String, dynamic> match;
  final bool isHistory;
  const MatchCardItem({super.key, required this.match, this.isHistory = false});
  @override
  State<MatchCardItem> createState() => _MatchCardItemState();
}

class _MatchCardItemState extends State<MatchCardItem> {
  Map<String, dynamic>? clubData;
  List<String> playerAvatars = [];

  @override
  void initState() { super.initState(); _loadDetails(); }

  Future<void> _loadDetails() async {
    try {
      if (widget.match['club_id'] != null) {
        final c = await supabase.from('clubs').select().eq('id', widget.match['club_id']).maybeSingle();
        if (mounted) setState(() => clubData = c);
      }
      final p = await supabase.from('participants').select('profiles(avatar_url)').eq('match_id', widget.match['id']).limit(4);
      if (mounted) {
        setState(() {
          playerAvatars = List<String>.from(p.map((e) => e['profiles'] != null ? (e['profiles']['avatar_url']?.toString() ?? "") : ""));
        });
      }
    } catch(e) { /* ignore */ }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final String title = (clubData != null ? clubData!['name'] : m['title'])?.toString() ?? "Матч";
    final String city = (clubData != null ? "${clubData!['city']}, ${clubData!['address']}" : m['location'])?.toString() ?? "Локация...";
    final String type = (m['type']?.toString() ?? 'Classic').toUpperCase();
    final String price = (m['price']?.toString() ?? "0");
    DateTime date; try { date = DateTime.parse(m['start_time'].toString()); } catch(e) { date = DateTime.now(); }
    int maxP = int.tryParse(m['max_players'].toString()) ?? 4;
    int currentP = int.tryParse(m['players_count'].toString()) ?? 0;
    
    final double minLevel = (m['level_min'] ?? 0).toDouble();
    final double maxLevel = (m['level_max'] ?? 7).toDouble();
    String levelStr = "${minLevel.toStringAsFixed(1)} - ${maxLevel.toStringAsFixed(1)}";
    
    final String score = m['score']?.toString() ?? "";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MatchLobbyScreen(match: m))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: widget.isHistory ? [] : [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.15), blurRadius: 20)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
               Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: widget.isHistory ? Colors.grey.withOpacity(0.2) : const Color(0xFF007AFF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(widget.isHistory ? "ЗАВЕРШЕН" : type, style: TextStyle(color: widget.isHistory ? Colors.grey : const Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 10))),
               const SizedBox(width: 8),
               Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)), child: Text("Lev: $levelStr", style: const TextStyle(color: Colors.white70, fontSize: 10))),
            ]),
            
            (widget.isHistory && score.isNotEmpty && score != "null")
              ? Text(score, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(color: Colors.green, blurRadius: 10)]))
              : Text("$price€", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text("${date.day}.${date.month} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            SizedBox(width: 80, height: 30, child: Stack(alignment: Alignment.centerRight, children: List.generate(playerAvatars.length, (i) => Positioned(right: i * 15.0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(playerAvatars[i].isEmpty ? "https://i.pravatar.cc/100" : playerAvatars[i]))))))
          ]),
          Align(alignment: Alignment.centerRight, child: Text("$currentP/$maxP", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)))
        ]),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 🔥 ЛОББИ: СЕТЫ, СЛОТЫ, ТИПЫ ИГР
// ----------------------------------------------------------------------
class MatchLobbyScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  const MatchLobbyScreen({super.key, required this.match});
  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _primaryBlue = const Color(0xFF007AFF);
  final Color _dangerRed = const Color(0xFFFF3B30);
  final Color _warningOrange = const Color(0xFFFF9500);

  List<Map<String, dynamic>> confirmedPlayers = [];
  List<Map<String, dynamic>> waitingList = [];
  bool isCreator = false;
  
  int _currentSet = 1; 
  final List<TextEditingController> _scoreControllers = List.generate(200, (_) => TextEditingController());
  
  // Таймер для отображения времени матча
  Timer? _matchTimer;
  Duration _matchDuration = Duration.zero;
  late DateTime _matchStartTime;

  @override
  void initState() {
    super.initState();
    isCreator = supabase.auth.currentUser?.id == widget.match['creator_id'];
    _loadParticipants();
    
    // Если матч уже IN_PROGRESS, запускаем таймер
    if (widget.match['status'] == 'IN_PROGRESS') {
      _matchStartTime = DateTime.now();
      _startMatchTimer();
    }
  }

  void _startMatchTimer() {
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _matchDuration = DateTime.now().difference(_matchStartTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    final res = await supabase.from('participants').select('user_id, status, slot_index, profiles(username, level, avatar_url)').eq('match_id', widget.match['id']);
    if (mounted) {
      setState(() {
        final all = List<Map<String, dynamic>>.from(res);
        confirmedPlayers = all.where((p) => p['status'] == 'CONFIRMED').toList();
        waitingList = all.where((p) => p['status'] == 'WAITING').toList();
      });
      confirmedPlayers.sort((a, b) => (a['slot_index'] ?? 99).compareTo(b['slot_index'] ?? 99));
      await supabase.from('matches').update({'players_count': confirmedPlayers.length}).eq('id', widget.match['id']);
    }
  }

  Future<void> _joinSpecificSlot(int slotIndex) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    if (widget.match['status'] == 'FINISHED') return;

    final isTaken = confirmedPlayers.any((p) => p['slot_index'] == slotIndex);
    if (isTaken) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Место занято!")));
       return;
    }

    try {
      final profileData = await supabase.from('profiles').select('level').eq('id', uid).single();
      final double userLevel = (profileData['level'] ?? 0).toDouble();
      final double minL = (widget.match['level_min'] ?? 0).toDouble();
      final double maxL = (widget.match['level_max'] ?? 7).toDouble();

      if (!isCreator && (userLevel < minL || userLevel > maxL)) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ваш рейтинг ($userLevel) не подходит. Требуется: $minL - $maxL"), backgroundColor: Colors.red));
         return;
      }

      await supabase.from('participants').delete().eq('match_id', widget.match['id']).eq('user_id', uid);
      await supabase.from('participants').insert({
        'match_id': widget.match['id'], 'user_id': uid, 'status': 'CONFIRMED', 'slot_index': slotIndex
      });
      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  Future<void> _leaveMatch() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      await supabase.from('participants').delete().eq('match_id', widget.match['id']).eq('user_id', uid);
      _loadParticipants();
    }
  }

  Future<void> _startMatch() async {
    try {
      // Обновляем статус матча в БД
      await supabase.from('matches').update({'status': 'IN_PROGRESS'}).eq('id', widget.match['id']);
      
      if (mounted) {
        // Переходим на экран управления матчем с таймером
        Navigator.push(context, MaterialPageRoute(builder: (c) => MatchControlScreen(match: widget.match)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  Future<void> _deleteMatch() async {
     final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(backgroundColor: _cardColor, title: const Text("Удалить игру?", style: TextStyle(color: Colors.white)), content: const Text("Вы уверены? Это действие необратимо."), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Отмена", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Удалить", style: TextStyle(color: Colors.red)))]));
     if(confirm == true) {
        try {
          await supabase.from('participants').delete().eq('match_id', widget.match['id']);
          await supabase.from('matches').delete().eq('id', widget.match['id']);
          if (mounted) Navigator.pop(context);
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
     }
  }

  Future<void> _finishMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text("Завершить матч?", style: TextStyle(color: Colors.white)),
        content: const Text("Матч будет перемещен в историю.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text("Завершить", style: TextStyle(color: _primaryBlue)))
        ]
      )
    );

    if (confirm == true) {
      String finalScore = "";
      String type = (widget.match['type'] ?? 'Classic').toString(); 

      if (type == 'Classic') {
        List<String> sets = [];
        for (int i = 0; i < 5; i++) {
          int cIdx1 = i * 8 + 0; 
          int cIdx2 = i * 8 + 1;
          String left = _scoreControllers[cIdx1].text.trim();
          String right = _scoreControllers[cIdx2].text.trim();
          if (left.isNotEmpty && right.isNotEmpty) sets.add("$left-$right");
        }
        finalScore = sets.join(" "); 
        if (finalScore.isEmpty) finalScore = "0-0"; 
      } else {
        finalScore = "Турнир"; 
      }

      try {
        await supabase.from('matches').update({'status': 'FINISHED', 'score': finalScore}).eq('id', widget.match['id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int courts = int.tryParse(widget.match['courts_count'].toString()) ?? 1;
    String type = widget.match['type']?.toString() ?? 'Classic';
    bool isClassic = type == 'Classic';
    bool isInProgress = widget.match['status'] == 'IN_PROGRESS';
    bool isFinished = widget.match['status'] == 'FINISHED';
    
    // 🔥 ОТОБРАЖЕНИЕ СЧЕТА В ЛОББИ ПОСЛЕ ЗАВЕРШЕНИЯ
    String scoreDisplay = widget.match['score']?.toString() ?? "";

    final uid = supabase.auth.currentUser?.id;
    bool amIJoined = confirmedPlayers.any((p) => p['user_id'] == uid);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(widget.match['title']?.toString() ?? "Лобби"), actions: [if (isCreator) IconButton(icon: Icon(Icons.delete_forever, color: _dangerRed), onPressed: _deleteMatch)]),
      body: SingleChildScrollView(
        child: Column(children: [
          
          // 🔥 ТАЙМЕР МАТЧА (если матч в процессе)
          if (isInProgress)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  const Text("ВРЕМЯ МАТЧА: ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    _formatDuration(_matchDuration),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          
          if (isInProgress && isClassic) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => _setButton(i + 1)))),
            const SizedBox(height: 15),
          ],

          if ((isInProgress || isFinished) && !isClassic) ...[
             const SizedBox(height: 10),
             ElevatedButton(
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TournamentScreen(title: widget.match['title'], matchId: widget.match['id'], courts: courts, gameType: type))),
               style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: const Size(300, 50)),
               child: const Text("ТУРНИРНАЯ ТАБЛИЦА")
             ),
             const SizedBox(height: 20),
          ],

          ...List.generate(courts, (i) => _buildCourt(i, isInProgress && isClassic, isFinished, scoreDisplay)),
          
          if (waitingList.isNotEmpty) ...[
             const Padding(padding: EdgeInsets.all(15), child: Align(alignment: Alignment.centerLeft, child: Text("Лист ожидания", style: TextStyle(color: Colors.grey)))),
             SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: waitingList.length, itemBuilder: (c, i) => _buildPlayer(waitingList[i]['profiles'], -1, false))),
          ],

          const SizedBox(height: 30),

          if (!isFinished) 
             Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
               if (!isInProgress) Expanded(child: ElevatedButton(onPressed: amIJoined ? _leaveMatch : null, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, minimumSize: const Size(0, 50)), child: const Text("ВЫЙТИ", style: TextStyle(fontWeight: FontWeight.bold)))),
               if (!isInProgress && isCreator) ...[
                 const SizedBox(width: 10),
                 Expanded(child: ElevatedButton(onPressed: _startMatch, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(0, 50)), child: const Text("СТАРТ", style: TextStyle(fontWeight: FontWeight.bold))))
               ]
             ])),

          if (isInProgress && isCreator)
             Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ElevatedButton(onPressed: _finishMatch, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)), child: const Text("ЗАВЕРШИТЬ МАТЧ", style: TextStyle(fontWeight: FontWeight.bold)))),
             
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _setButton(int setNum) {
    bool isActive = _currentSet == setNum;
    return GestureDetector(
      onTap: () => setState(() => _currentSet = setNum),
      child: Container(margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? _primaryBlue : _cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? _primaryBlue : Colors.white24)), child: Text("Сет $setNum", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildCourt(int index, bool showScore, bool isFinished, String finalScore) {
    int baseControllerIndex = (_currentSet - 1) * 8 + (index * 2); 

    Widget centerWidget = const Text("VS", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 24));

    if (showScore) {
       centerWidget = Row(children: [SizedBox(width: 35, child: TextField(controller: _scoreControllers[baseControllerIndex], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22), keyboardType: TextInputType.number)), const Text(":", style: TextStyle(color: Colors.white, fontSize: 22)), SizedBox(width: 35, child: TextField(controller: _scoreControllers[baseControllerIndex + 1], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22), keyboardType: TextInputType.number))]);
    } else if (isFinished) {
       centerWidget = Text(finalScore, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24, fontStyle: FontStyle.italic, shadows: [Shadow(color: Colors.green, blurRadius: 10)]));
    }

    return Container(margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(children: [
        Text("КОРТ ${index + 1}", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [_buildSlot(index * 4), const SizedBox(height: 10), _buildSlot(index * 4 + 1)]),
          centerWidget,
          Column(children: [_buildSlot(index * 4 + 2), const SizedBox(height: 10), _buildSlot(index * 4 + 3)]),
        ])
      ]));
  }

  Widget _buildSlot(int slotIndex) {
    final player = confirmedPlayers.firstWhere((p) => p['slot_index'] == slotIndex, orElse: () => {});
    if (player.isNotEmpty) return _buildPlayer(player['profiles'], slotIndex, false);
    return GestureDetector(
      onTap: () => _joinSpecificSlot(slotIndex),
      child: Column(children: [
         Container(width: 65, height: 65, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1.5)), child: const Icon(Icons.add, color: Colors.white54)),
         const SizedBox(height: 5),
         const Text("Свободно", style: TextStyle(color: Colors.white24, fontSize: 10))
      ]),
    );
  }

  Widget _buildPlayer(dynamic profile, int slotIndex, bool isWait) {
    if (profile == null) return const SizedBox();
    final String level = profile['level']?.toString() ?? "?.?";
    return Column(children: [
         Stack(clipBehavior: Clip.none, children: [
           CircleAvatar(radius: 32, backgroundImage: NetworkImage(profile['avatar_url'] ?? "https://i.pravatar.cc/150")),
           Positioned(bottom: -6, left: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(vertical: 1), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: _primaryBlue)), child: Text(level, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))
         ]),
         const SizedBox(height: 10),
         Text(profile['username'] ?? "Игрок", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
    ]);
  }

  // Форматирование времени в 00:00:00
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}