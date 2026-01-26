import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для копирования
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _textWhite = Colors.white;

  List<Map<String, dynamic>> members = [];
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final uid = supabase.auth.currentUser!.id;
    
    // Загружаем участников + их профили
    final res = await supabase.from('group_members')
        .select('role, profiles(id, username, avatar_url, level)')
        .eq('group_id', widget.group['id']);

    if (mounted) {
      setState(() {
        members = List<Map<String, dynamic>>.from(res);
        // Проверяем, админ ли я
        final myRecord = members.firstWhere(
          (m) => m['profiles']['id'] == uid, 
          orElse: () => {'role': 'member'}
        );
        isAdmin = myRecord['role'] == 'admin';
        isLoading = false;
      });
    }
  }

  void _copyInviteCode() {
    // Пока сделаем просто копирование ID группы
    // В будущем можно сделать красивые ссылки padel-app://join/...
    Clipboard.setData(ClipboardData(text: widget.group['id'].toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ID группы скопирован! Отправь его другу."), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        title: Text(widget.group['name'], style: TextStyle(color: _textWhite)),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // Тут будут настройки группы (удалить, изменить имя)
              },
            )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Шапка группы
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 40, backgroundColor: Colors.blue, child: Icon(Icons.groups, size: 40, color: Colors.white)),
                        const SizedBox(height: 15),
                        Text(widget.group['description'] ?? "Нет описания", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2E)),
                          onPressed: _copyInviteCode,
                          icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                          label: const Text("Копировать ID приглашения", style: TextStyle(color: Colors.blue)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Список участников
                  Text("Участники (${members.length})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  ...members.map((m) {
                    final profile = m['profiles'];
                    final role = m['role'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                            child: profile['avatar_url'] == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile['username'] ?? "User", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold)),
                                Text("Level: ${profile['level'] ?? 0}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (role == 'admin')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text("Admin", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}