import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'tournament_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // Цвета
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _primaryBlue = const Color(0xFF007AFF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF8E8E93);

  // 🔥 ИСПРАВЛЕНИЕ 1: Убрали late, добавили ?, чтобы не было ошибки при старте
  Stream<List<Map<String, dynamic>>>? _matchesStream;
  List<int> _myGroupIds = []; // ID групп, в которых я состою

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      // 1. Узнаем, в каких группах состоит пользователь
      final membersData = await supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', uid);
      if (mounted) {
        setState(() {
          _myGroupIds = List<int>.from(membersData.map((e) => e['group_id']));
        });
      }
    }

    // 2. Стрим матчей с фильтрацией на клиенте
    final stream = supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: true)
        .map((data) {
          return data.where((m) {
            if (m['status'] == 'FINISHED') return false;

            // Логика видимости:
            final matchGroupId = m['group_id'];
            // Если группы нет (null) -> Публичный матч
            if (matchGroupId == null) return true;

            // Если есть группа -> показываем, только если я в ней есть
            return _myGroupIds.contains(matchGroupId);
          }).toList();
        });

    if (mounted) {
      setState(() {
        _matchesStream = stream;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text("Матчи",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: _textWhite,
                fontFamily: '.SF Pro Display')),
        actions: [
          IconButton(
              icon: Icon(Icons.filter_list, color: _primaryBlue),
              onPressed: () {})
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showCreateMatchSheet(context),
      ),
      // 🔥 ИСПРАВЛЕНИЕ: Проверяем на null
      body: _matchesStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _matchesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.sports_tennis,
                            size: 60, color: _textGrey.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text("Нет активных матчей",
                            style: TextStyle(color: _textGrey, fontSize: 16))
                      ]));
                }
                final matches = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 20),
                  itemBuilder: (context, index) =>
                      MatchCardItem(match: matches[index]),
                );
              },
            ),
    );
  }

  // 🔥 МЕНЮ СОЗДАНИЯ С ВЫБОРОМ ГРУППЫ 🔥
  void _showCreateMatchSheet(BuildContext context) {
    bool isCompetitive = true;
    String title = "";
    double price = 0;

    // ✅ ПОЛНЫЙ СПИСОК ФОРМАТОВ
    final List<String> formats = [
      'Classic',
      'Americano',
      'Americano (Team)',
      'Americano (Mixed)',
      'Mexicano',
      'Mexicano (Team)',
      'Super Mexicano',
      'Winner Court',
      'Tournament'
    ];
    String selectedFormat = 'Classic';
    int courts = 1;
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    // Данные для списков
    List<Map<String, dynamic>> clubsList = [];
    String? selectedClubId;
    List<Map<String, dynamic>> myGroupsList = [];
    String? selectedGroupId; // null = Публичный

    bool isLoadingData = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Грузим данные
            if (isLoadingData) {
              Future.wait([
                supabase.from('clubs').select('id, name, city'),
                // Используем .filter вместо .in_
                supabase.from('groups').select('id, name').filter(
                    'id', 'in', _myGroupIds.isEmpty ? [-1] : _myGroupIds)
              ]).then((results) {
                setSheetState(() {
                  // Явное приведение типов
                  clubsList =
                      List<Map<String, dynamic>>.from(results[0] as List);
                  myGroupsList =
                      List<Map<String, dynamic>>.from(results[1] as List);

                  if (clubsList.isNotEmpty) {
                    selectedClubId = clubsList.first['id'].toString();
                  }
                  isLoadingData = false;
                });
              });
              isLoadingData = false;
            }
            Future<void> pickDateTime() async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (context, child) =>
                      Theme(data: ThemeData.dark(), child: child!));
              if (date == null) return;
              final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  builder: (context, child) =>
                      Theme(data: ThemeData.dark(), child: child!));
              if (time == null) return;
              setSheetState(() => selectedDateTime = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute));
            }

            // 🔥 ИСПРАВЛЕНИЕ 2: Добавили SingleChildScrollView
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            color: Colors.grey[600],
                            margin: const EdgeInsets.only(bottom: 20))),
                    const Center(
                        child: Text("Новая игра",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(height: 25),

                    // 1. ВЫБОР: ПУБЛИЧНЫЙ или ДЛЯ ГРУППЫ
                    _label("Видимость"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedGroupId,
                          dropdownColor: const Color(0xFF2C2C2E),
                          style:
                              const TextStyle(color: Colors.white, fontSize: 16),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null,
                                child: Text("🌍 Для всех (Публичный)")),
                            ...myGroupsList.map((g) => DropdownMenuItem<String?>(
                                value: g['id'].toString(),
                                child: Text("🔒 Группа: ${g['name']}")))
                          ],
                          onChanged: (val) =>
                              setSheetState(() => selectedGroupId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _label("Клуб"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClubId,
                          hint: const Text("Загрузка...",
                              style: TextStyle(color: Colors.grey)),
                          dropdownColor: const Color(0xFF2C2C2E),
                          style:
                              const TextStyle(color: Colors.white, fontSize: 16),
                          isExpanded: true,
                          items: clubsList
                              .map((club) => DropdownMenuItem<String>(
                                  value: club['id'].toString(),
                                  child: Text("${club['name']}",
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedClubId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(children: [
                      Expanded(
                          flex: 2,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Формат"),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C2E),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                            value: selectedFormat,
                                            dropdownColor:
                                                const Color(0xFF2C2C2E),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                            isExpanded: true,
                                            items: formats
                                                .map((f) => DropdownMenuItem(
                                                    value: f,
                                                    child: Text(f,
                                                        overflow: TextOverflow
                                                            .ellipsis)))
                                                .toList(),
                                            onChanged: (val) => setSheetState(
                                                () => selectedFormat = val!))))
                              ])),
                      const SizedBox(width: 15),
                      Expanded(
                          flex: 1,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Корты"),
                                Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C2E),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          InkWell(
                                              onTap: () => setSheetState(() {
                                                    if (courts > 1) courts--;
                                                  }),
                                              child: const Icon(Icons.remove,
                                                  color: Colors.grey, size: 20)),
                                          Text("$courts",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          InkWell(
                                              onTap: () =>
                                                  setSheetState(() => courts++),
                                              child: const Icon(Icons.add,
                                                  color: Color(0xFF007AFF),
                                                  size: 20))
                                        ]))
                              ])),
                    ]),
                    Padding(
                        padding: const EdgeInsets.only(top: 5, right: 5),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Text("Макс. игроков: ${courts * 4}",
                                style: const TextStyle(
                                    color: Color(0xFF007AFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 10),

                    Row(children: [
                      Expanded(
                          child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => isCompetitive = true),
                              child: _typeBtn("Ranked", isCompetitive))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => isCompetitive = false),
                              child: _typeBtn("Friendly", !isCompetitive)))
                    ]),
                    const SizedBox(height: 15),

                    _label("Дата"),
                    GestureDetector(
                        onTap: pickDateTime,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(Icons.calendar_month,
                                  color: Color(0xFF007AFF)),
                              const SizedBox(width: 10),
                              Text(
                                  "${selectedDateTime.day}.${selectedDateTime.month} | ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              const Icon(Icons.edit,
                                  color: Colors.grey, size: 16)
                            ]))),
                    const SizedBox(height: 15),

                    Row(children: [
                      Expanded(
                          flex: 2,
                          child: _input("Название (опц.)", (v) => title = v)),
                      const SizedBox(width: 10),
                      Expanded(
                          flex: 1,
                          child: _input(
                              "Цена €", (v) => price = double.tryParse(v) ?? 0,
                              isNum: true))
                    ]),
                    const SizedBox(height: 30),

                    SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () async {
                            try {
                              final uid = supabase.auth.currentUser?.id;
                              if (uid == null) throw "Войдите в профиль";
                              if (selectedClubId == null) throw "Выберите клуб!";

                              await supabase.from('matches').insert({
                                'creator_id': uid,
                                'title': title.isEmpty ? "Match" : title,
                                'club_id': int.parse(selectedClubId!),
                                'group_id': selectedGroupId != null
                                    ? int.parse(selectedGroupId!)
                                    : null, // ГРУППА
                                'is_competitive': isCompetitive,
                                'price': price,
                                'type': selectedFormat,
                                'courts_count': courts,
                                'max_players': courts * 4,
                                'status': 'OPEN',
                                'players_count': 0,
                                'start_time': selectedDateTime.toIso8601String(),
                              });
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text("Ошибка: $e"),
                                  backgroundColor: Colors.red));
                            }
                          },
                          child: const Text("Создать матч",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        )),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child:
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)));

  Widget _typeBtn(String text, bool active) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: active
                ? const Color(0xFF007AFF).withOpacity(0.2)
                : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: const Color(0xFF007AFF)) : null),
        child: Center(
            child: Text(text,
                style: TextStyle(
                    color: active ? const Color(0xFF007AFF) : Colors.white,
                    fontWeight: FontWeight.bold))));
  }

  Widget _input(String label, Function(String) onChange, {bool isNum = false}) {
    return TextField(
        style: const TextStyle(color: Colors.white),
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none)),
        onChanged: onChange);
  }
}

// -------------------------------------------------------------
// 🔥 КАРТОЧКА С ПОДСВЕТКОЙ (GLOW) И АВАТАРКАМИ
// -------------------------------------------------------------
class MatchCardItem extends StatefulWidget {
  final Map<String, dynamic> match;
  const MatchCardItem({super.key, required this.match});

  @override
  State<MatchCardItem> createState() => _MatchCardItemState();
}

class _MatchCardItemState extends State<MatchCardItem> {
  Map<String, dynamic>? clubData;
  List<String> playerAvatars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (widget.match['club_id'] != null) {
      final c = await supabase
          .from('clubs')
          .select()
          .eq('id', widget.match['club_id'])
          .maybeSingle();
      if (mounted) setState(() => clubData = c);
    }

    final p = await supabase
        .from('participants')
        .select('profiles(avatar_url)')
        .eq('match_id', widget.match['id'])
        .limit(4);
    if (mounted) {
      setState(() {
        playerAvatars = List<String>.from(p.map((e) =>
            e['profiles'] != null ? (e['profiles']['avatar_url'] ?? "") : ""));
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final String title =
        clubData != null ? clubData!['name'] : (m['title'] ?? "Match");
    final String city = clubData != null
        ? "${clubData!['city']}, ${clubData!['address']}"
        : "Локация...";
    final String type = m['type'] ?? 'Classic';

    final date = DateTime.tryParse(m['start_time']) ?? DateTime.now();
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final dateStr = "${date.day}.${date.month}";

    int maxP = m['max_players'] ?? 4;
    int currentP = m['players_count'] ?? 0;

    // Метка группы
    final bool isPrivate = m['group_id'] != null;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => MatchLobbyScreen(match: m))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Хедер
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(type.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                    if (isPrivate) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock,
                          size: 14, color: Colors.orangeAccent)
                    ]
                  ],
                ),
                Text("${m['price']}€",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(city,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis)),
            ]),

            const SizedBox(height: 18),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // Футер
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text("$dateStr | $timeStr",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  width: 85,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      if (playerAvatars.isEmpty)
                        const Positioned(
                            right: 0,
                            child: Text("0",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12))),
                      ...List.generate(playerAvatars.length, (index) {
                        return Positioned(
                          right: index * 20.0,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF1C1C1E), width: 2),
                                shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: playerAvatars[index].isNotEmpty
                                  ? NetworkImage(playerAvatars[index])
                                  : null,
                              child: playerAvatars[index].isEmpty
                                  ? const Icon(Icons.person,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text("$currentP/$maxP",
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 🔥 ПОЛНОЦЕННОЕ ЛОББИ (Кнопки Старт, Удалить, Waitlist)
// ----------------------------------------------------------------------
class MatchLobbyScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  const MatchLobbyScreen({super.key, required this.match});
  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _primaryBlue = const Color(0xFF007AFF);
  final Color _dangerRed = const Color(0xFFFF3B30);
  final Color _warningOrange = const Color(0xFFFF9500);

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
    if (uid != null && uid == widget.match['creator_id']) {
      setState(() => isCreator = true);
    }
  }

  Future<void> _loadParticipants() async {
    final res = await supabase
        .from('participants')
        .select('user_id, status, profiles(username, level, avatar_url)')
        .eq('match_id', widget.match['id']);

    if (mounted) {
      setState(() {
        var all = List<Map<String, dynamic>>.from(res);
        confirmedPlayers =
            all.where((p) => p['status'] == 'CONFIRMED').toList();
        waitingList = all.where((p) => p['status'] == 'WAITING').toList();
      });
      await supabase
          .from('matches')
          .update({'players_count': confirmedPlayers.length}).eq(
              'id', widget.match['id']);
    }
  }

  Future<void> _joinSlot() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;

      final inConfirmed = confirmedPlayers.any((p) => p['user_id'] == uid);
      final inWaiting = waitingList.any((p) => p['user_id'] == uid);

      if (inConfirmed || inWaiting) {
        await supabase
            .from('participants')
            .delete()
            .eq('match_id', widget.match['id'])
            .eq('user_id', uid);
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Вы покинули игру")));
      } else {
        int maxP = widget.match['max_players'] ?? 4;
        String status = 'CONFIRMED';
        if (confirmedPlayers.length >= maxP) {
          status = 'WAITING';
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Мест нет. Вы в очереди."),
                backgroundColor: _warningOrange));
        }
        await supabase.from('participants').insert(
            {'match_id': widget.match['id'], 'user_id': uid, 'status': status});
      }
      _loadParticipants();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка: $e"), backgroundColor: _dangerRed));
    }
  }

  Future<void> _deleteMatch() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: _cardColor,
              title: const Text("Удалить игру?",
                  style: TextStyle(color: Colors.white)),
              content: const Text("Действие необратимо.",
                  style: TextStyle(color: Colors.grey)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text("Отмена",
                        style: TextStyle(color: Colors.grey))),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child:
                        Text("Удалить", style: TextStyle(color: _dangerRed))),
              ],
            ));

    if (confirm == true) {
      try {
        await supabase
            .from('participants')
            .delete()
            .eq('match_id', widget.match['id']);
        await supabase.from('matches').delete().eq('id', widget.match['id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
      }
    }
  }

  void _startGame() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => TournamentScreen(
                  title: widget.match['title'] ?? "Match",
                  matchId: widget.match['id'],
                  courts: widget.match['courts_count'] ?? 1,
                  gameType: widget.match['type'] ?? 'Classic',
                )));
  }

  @override
  Widget build(BuildContext context) {
    bool isCompetitive = widget.match['is_competitive'] ?? true;
    int courts = widget.match['courts_count'] ?? 1;

    final club = widget.match['clubs'];
    String address = club != null
        ? "${club['name']}, ${club['address']}"
        : (widget.match['club_name'] ?? "");

    final uid = supabase.auth.currentUser?.id;
    bool inConfirmed = confirmedPlayers.any((p) => p['user_id'] == uid);
    bool inWaiting = waitingList.any((p) => p['user_id'] == uid);
    int maxPlayers = widget.match['max_players'] ?? (courts * 4);
    bool isFull = confirmedPlayers.length >= maxPlayers;

    String btnText = inConfirmed
        ? "Выйти"
        : (inWaiting
            ? "Покинуть очередь"
            : (isFull ? "Встать в очередь" : "Записаться"));
    Color btnColor = inConfirmed
        ? _dangerRed
        : (inWaiting
            ? _warningOrange
            : (isFull ? _warningOrange : _primaryBlue));

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
          backgroundColor: _bgDark,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.match['title'] ?? "Матч",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (address.isNotEmpty)
              Text(address,
                  style: const TextStyle(color: Colors.grey, fontSize: 10))
          ]),
          actions: [
            if (isCreator)
              IconButton(
                  icon: Icon(Icons.delete_forever, color: _dangerRed),
                  onPressed: _deleteMatch)
          ]),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _tabBtn("Info", false),
                  const SizedBox(width: 10),
                  _tabBtn("Schedule", true),
                  const SizedBox(width: 10),
                  _tabBtn("Statistics", false)
                ])),
            const SizedBox(height: 20),

            Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)),
                child: Row(children: [
                  Icon(isCompetitive ? Icons.emoji_events : Icons.tag_faces,
                      color: isCompetitive
                          ? const Color(0xFFF2C94C)
                          : Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          isCompetitive ? "Рейтинговый матч" : "Дружеский матч",
                          style: const TextStyle(color: Colors.white70)))
                ])),
            const SizedBox(height: 30),

            // КОРТЫ
            Column(
              children: List.generate(courts, (courtIndex) {
                int baseIndex = courtIndex * 4;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                  child: Column(
                    children: [
                      Text("КОРТ ${courtIndex + 1}",
                          style: TextStyle(
                              color: _primaryBlue,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            _playerSlot(baseIndex),
                            const SizedBox(height: 20),
                            _playerSlot(baseIndex + 1)
                          ]),
                          SizedBox(
                              height: 150,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                        width: 2,
                                        height: 40,
                                        color: Colors.white10),
                                    Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: _cardColor,
                                            border: Border.all(
                                                color: Colors.white24),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Text("VS",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white54))),
                                    Container(
                                        width: 2,
                                        height: 40,
                                        color: Colors.white10)
                                  ])),
                          Column(children: [
                            _playerSlot(baseIndex + 2),
                            const SizedBox(height: 20),
                            _playerSlot(baseIndex + 3)
                          ]),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            if (waitingList.isNotEmpty) ...[
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Лист ожидания:",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)))),
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
                            child: Column(children: [
                              CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(
                                      p['avatar_url'] ??
                                          "https://i.pravatar.cc/150"),
                                  backgroundColor:
                                      _warningOrange.withOpacity(0.2)),
                              const SizedBox(height: 5),
                              Text(p['username'] ?? "Wait",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 10))
                            ]));
                      })),
              const SizedBox(height: 20),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                              onPressed: _joinSlot,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: btnColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30))),
                              child: Text(btnText,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18))))),
                  if (isCreator) ...[
                    const SizedBox(width: 10),
                    Expanded(
                        child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                                onPressed: _startGame,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34C759),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30))),
                                child: const Text("СТАРТ",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)))))
                  ]
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
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: isActive ? _primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive ? null : Border.all(color: Colors.white24)),
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        color: isActive ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold)))));
  }

  Widget _playerSlot(int index) {
    Map<String, dynamic>? player;
    if (index < confirmedPlayers.length) player = confirmedPlayers[index];
    if (player != null) {
      final profile = player['profiles'];
      return Column(children: [
        CircleAvatar(
            radius: 35,
            backgroundColor: _cardColor,
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? const Icon(Icons.person, size: 40, color: Colors.white54)
                : null),
        const SizedBox(height: 5),
        Text(profile['username'] ?? "Игрок",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white))
      ]);
    } else {
      return GestureDetector(
          onTap: _joinSlot,
          child: Column(children: [
            Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10, width: 2)),
                child: const Icon(Icons.add, color: Colors.white24, size: 30)),
            const SizedBox(height: 5),
            const Text("Добавить", style: TextStyle(color: Colors.white24))
          ]));
    }
  }
}