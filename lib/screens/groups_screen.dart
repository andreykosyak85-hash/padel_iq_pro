import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // Стиль
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _primaryBlue = const Color(0xFF007AFF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF8E8E93);

  late final Stream<List<Map<String, dynamic>>> _groupsStream;

  @override
  void initState() {
    super.initState();
    // Грузим группы. 
    // В идеале здесь нужен сложный SQL запрос "группы, где я участник".
    // Пока оставляем как есть (все группы), чтобы ты мог видеть результат.
    _groupsStream = supabase
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // --- ЛОГИКА: СОЗДАНИЕ ГРУППЫ ---
  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Новая группа", style: TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             _input(nameController, "Название группы"),
             const SizedBox(height: 15),
             _input(descController, "Описание (опц.)"),
             const SizedBox(height: 25),
             SizedBox(
               width: double.infinity, height: 50,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                 onPressed: () async {
                   final name = nameController.text.trim();
                   if (name.isEmpty) return;
                   
                   try {
                     await supabase.from('groups').insert({
                       'name': name,
                       'description': descController.text.trim(),
                       'creator_id': supabase.auth.currentUser!.id
                     });
                     if (mounted) Navigator.pop(context);
                   } catch(e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
                   }
                 },
                 child: const Text("Создать", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             )
          ],
        ),
      )
    );
  }

  // --- ЛОГИКА: ВСТУПИТЬ В ГРУППУ ПО ID ---
  void _showJoinGroupDialog() {
    final idController = TextEditingController();

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text("Вступить в группу", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Введите ID группы, который вам дал друг:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.black26,
                hintText: "Например: 12",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () async {
              final idStr = idController.text.trim();
              if (idStr.isEmpty) return;
              
              try {
                final int groupId = int.parse(idStr);
                final uid = supabase.auth.currentUser!.id;

                // Пробуем добавиться в таблицу участников
                await supabase.from('group_members').insert({
                  'group_id': groupId,
                  'user_id': uid,
                  'role': 'member'
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Вы успешно вступили!"), backgroundColor: Colors.green));
                }
              } catch (e) {
                // Скорее всего ошибка "duplicate key" (уже в группе) или "violation" (группы нет)
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ошибка: Неверный ID или вы уже там."), backgroundColor: Colors.red));
                }
              }
            }, 
            child: const Text("Вступить", style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _textWhite),
      decoration: InputDecoration(
        labelText: hint, labelStyle: TextStyle(color: _textGrey),
        filled: true, fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark, elevation: 0,
        title: Text("Сообщества", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: '.SF Pro Display')),
        actions: [
          // Кнопка ВСТУПИТЬ
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white), 
            tooltip: "Вступить по ID",
            onPressed: _showJoinGroupDialog
          ),
          // Кнопка СОЗДАТЬ
          IconButton(
            icon: Icon(Icons.add_circle, color: _primaryBlue), 
            onPressed: _showCreateGroupDialog
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data!;
          
          if (groups.isEmpty) return Center(child: Text("Нет групп. Создайте или вступите!", style: TextStyle(color: _textGrey)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              
              // 🔥 ДОБАВЛЕН ПЕРЕХОД (GestureDetector)
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(group: group)
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.groups, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group['name'], style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                            if (group['description'] != null)
                               Text(group['description'], style: TextStyle(color: _textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _textGrey)
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}