import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF8E8E93);

  String _searchQuery = "";
  List<int> _myGroupIds = [];
  late Stream<List<Map<String, dynamic>>> _groupsStream;

  @override
  void initState() {
    super.initState();
    _loadMyGroupIds();
    _initStream();
  }

  void _initStream() {
    _groupsStream = supabase
        .from('groups')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  // Обновляем список ID групп, где я состою
  Future<void> _loadMyGroupIds() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    
    // Делаем небольшую задержку, чтобы база успела обновиться после создания/удаления
    await Future.delayed(const Duration(milliseconds: 300));

    final res = await supabase
        .from('group_members')
        .select('group_id')
        .eq('user_id', uid);
    if (mounted) {
      setState(() {
        _myGroupIds = List<int>.from(res.map((e) => e['group_id']));
      });
    }
  }

  // Переход к созданию группы с ожиданием результата
  // Переход к созданию группы с "умным" обновлением
  void _goToCreateGroup() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (c) => const CreateGroupScreen()));

    // Если группа создана...
    if (result == true) {
      // ⏳ ШАГ 1: Даем базе полсекунды, чтобы точно успеть сохранить данные
      await Future.delayed(const Duration(milliseconds: 500));

      // ШАГ 2: Грузим обновленный список ID моих групп
      await _loadMyGroupIds();

      // ШАГ 3: Жестко перезапускаем поток данных, чтобы увидеть новую группу
      setState(() {
        _groupsStream = supabase
            .from('groups')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false);
      });
    }
  }
  // Переход в детали группы с ожиданием результата (удаления)
  void _goToGroupDetail(Map<String, dynamic> group) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (c) => GroupDetailScreen(group: group)));

    // Если вернулось true (группа удалена), обновляем список
    if (result == true) {
      await _loadMyGroupIds();
      setState(() {});
    }
  }

  void _showJoinGroupDialog() {
    final idController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: _cardColor,
              title: const Text("Вступить в группу",
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black26,
                    hintText: "ID группы (например: 12)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Отмена")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF)),
                    onPressed: () async {
                      final idStr = idController.text.trim();
                      if (idStr.isEmpty) return;
                      try {
                        final int groupId = int.parse(idStr);
                        final uid = supabase.auth.currentUser!.id;
                        await supabase.from('group_members').insert({
                          'group_id': groupId,
                          'user_id': uid,
                          'role': 'member'
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadMyGroupIds(); // Обновляем список
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Вы успешно вступили!"),
                                  backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("Ошибка: Неверный ID или вы уже там."),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: const Text("Вступить",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: const Text("Сообщества",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28)),
        actions: [
          IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white),
              onPressed: _showJoinGroupDialog),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.add_circle,
                  color: Color(0xFF007AFF), size: 30),
              onPressed: _goToCreateGroup,
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGroups = snapshot.data!;
          final visibleGroups = _searchQuery.isEmpty
              ? allGroups
              : allGroups
                  .where((g) => g['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          // Разделяем на Мои и Чужие
          final myGroups = visibleGroups
              .where((g) => _myGroupIds.contains(g['id']))
              .toList();
          final otherGroups = visibleGroups
              .where((g) => !_myGroupIds.contains(g['id']))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ПОИСК
                TextField(
                  style: TextStyle(color: _textWhite),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                      hintText: "Поиск...",
                      hintStyle: TextStyle(color: _textGrey),
                      prefixIcon: Icon(Icons.search, color: _textGrey),
                      filled: true,
                      fillColor: _cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                ),
                const SizedBox(height: 25),

                // FAVORITES (Мои группы)
                if (myGroups.isNotEmpty) ...[
                  Text("Мои группы",
                      style: TextStyle(
                          color: _textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: myGroups.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _goToGroupDetail(myGroups[index]), // 🔥 Навигация здесь
                        child: _GroupCard(group: myGroups[index], isMember: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // EXPLORE (Найти еще)
                if (otherGroups.isNotEmpty) ...[
                  Text("Найти еще",
                      style: TextStyle(
                          color: _textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: otherGroups.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _goToGroupDetail(otherGroups[index]), // 🔥 Навигация здесь
                        child: _GroupCard(group: otherGroups[index], isMember: false),
                      ),
                    ),
                  ),
                ],
                
                if(myGroups.isEmpty && otherGroups.isEmpty)
                   Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text("Групп пока нет", style: TextStyle(color: _textGrey)))),
              ],
            ),
          );
        },
      ),
    );
  }
}

// КАРТОЧКА ГРУППЫ (Только дизайн, без логики клика)
class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isMember;

  const _GroupCard({required this.group, required this.isMember});

  @override
  Widget build(BuildContext context) {
    bool isPrivate = group['is_private'] ?? false;
    String location = group['location'] ?? "Нет локации";

    return Container(
      width: 280, // Фиксированная ширина для горизонтального скролла
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: group['image_url'] != null
              ? NetworkImage(group['image_url'])
              : const NetworkImage(
                  "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?q=80&w=2070"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isPrivate)
            const Row(
              children: [
                Icon(Icons.lock, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text("Private",
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))
              ],
            ),
          Text(group['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(location,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: isMember
                        ? const Color(0xFF34C759)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isMember ? "Вы участник" : (isPrivate ? "Запрос" : "Войти"),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}