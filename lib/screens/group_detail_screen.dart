import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  final Color _dangerRed = const Color(0xFFFF3B30);

  List<Map<String, dynamic>> members = [];
  bool isAdmin = false;
  bool isLoading = true;
  String? groupImageUrl;

  @override
  void initState() {
    super.initState();
    groupImageUrl = widget.group['image_url'];
    _loadMembers();
  }

  // Загружаем участников (надежный способ без сложных JOIN)
  Future<void> _loadMembers() async {
    try {
      final uid = supabase.auth.currentUser?.id;

      // 1. Берем сырые данные участников
      final membersData = await supabase.from('group_members')
          .select('user_id, role')
          .eq('group_id', widget.group['id']);

      final List<dynamic> rawList = membersData as List<dynamic>;
      
      if (rawList.isEmpty) {
        if (mounted) setState(() { members = []; isLoading = false; });
        return;
      }

      // 2. Собираем ID всех юзеров
      final userIds = rawList.map((m) => m['user_id']).toList();

      // 3. Грузим профили этих юзеров
      final profilesData = await supabase.from('profiles')
          .select('id, username, level, avatar_url')
          .filter('id', 'in', userIds);

      // 4. Объединяем вручную
      final combinedList = rawList.map((member) {
        // ИСПРАВЛЕНИЕ ЗДЕСЬ: Возвращаем пустую Map {}, а не null
        final profile = profilesData.firstWhere(
            (p) => p['id'] == member['user_id'],
            orElse: () => <String, dynamic>{}); 
            
        return {
          'role': member['role'],
          'profiles': profile.isNotEmpty ? profile : null // Проверяем на пустоту
        };
      }).toList();

      if (mounted) {
        setState(() {
          members = combinedList;
          // Проверяем админа
          if (uid != null) {
            final myRecord = members.firstWhere(
              (m) => m['profiles'] != null && m['profiles']['id'] == uid,
              orElse: () => {},
            );
            if (myRecord.isNotEmpty && myRecord['role'] == 'admin') {
              isAdmin = true;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Ошибка: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Загрузка фото (Работает и в Web, и на телефоне)
  Future<void> _uploadImage() async {
    if (!isAdmin) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 500);

    if (image == null) return;

    try {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Загрузка фото...")));

      final fileExt = image.name.split('.').last;
      final fileName = '${widget.group['id']}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // Читаем байты (универсально для Web/Mobile)
      final bytes = await image.readAsBytes();

      await supabase.storage.from('group_avatars').uploadBinary(
        fileName, 
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt')
      );

      final imageUrl = supabase.storage.from('group_avatars').getPublicUrl(fileName);
      // Добавляем timestamp, чтобы обновить кэш картинки
      final finalUrl = "$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      await supabase.from('groups').update({'image_url': finalUrl}).eq('id', widget.group['id']);

      if (mounted) {
        setState(() {
          groupImageUrl = finalUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Фото обновлено!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text("Удалить группу?", style: TextStyle(color: Colors.white)),
        content: const Text("Это действие нельзя отменить.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Нет")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Удалить", style: TextStyle(color: _dangerRed))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('group_members').delete().eq('group_id', widget.group['id']);
      await supabase.from('groups').delete().eq('id', widget.group['id']);
      
      if (mounted) {
        // Возвращаем true, чтобы список групп обновился
        Navigator.pop(context, true); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: widget.group['id'].toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("ID скопирован!"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        title: Text(widget.group['name'], style: TextStyle(color: _textWhite)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.delete_forever, color: _dangerRed),
              onPressed: _deleteGroup,
            )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isAdmin ? _uploadImage : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                            image: groupImageUrl != null 
                              ? DecorationImage(image: NetworkImage(groupImageUrl!), fit: BoxFit.cover)
                              : null
                          ),
                          child: groupImageUrl == null 
                            ? const Icon(Icons.groups, size: 50, color: Colors.white)
                            : null,
                        ),
                        if (isAdmin)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                            ),
                          )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  Text(widget.group['description'] ?? "Нет описания", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _cardColor),
                    onPressed: _copyInviteCode,
                    icon: const Icon(Icons.copy, size: 16, color: Color(0xFF007AFF)),
                    label: Text("ID: ${widget.group['id']}", style: const TextStyle(color: Color(0xFF007AFF))),
                  ),

                  const SizedBox(height: 30),
                  Align(alignment: Alignment.centerLeft, child: Text("Участники (${members.length})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  
                  if (members.isEmpty) const Text("Список пуст", style: TextStyle(color: Colors.grey)),

                  ...members.map((m) {
                    final profile = m['profiles'];
                    final role = m['role'];
                    if (profile == null) return const SizedBox.shrink();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: profile['avatar_url'] != null && profile['avatar_url'].isNotEmpty
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: (profile['avatar_url'] == null || profile['avatar_url'].isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(profile['username'] ?? "User", style: TextStyle(color: _textWhite)),
                      trailing: role == 'admin' 
                          ? const Text("Admin", style: TextStyle(color: Color(0xFF007AFF), fontSize: 12)) 
                          : null,
                    );
                  })
                ],
              ),
            ),
    );
  }
}