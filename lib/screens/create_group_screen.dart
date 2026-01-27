import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _inputColor = const Color(0xFF2C2C2E);
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isPrivate = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _clubs = [];
  String? _selectedClubId;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final res = await supabase.from('clubs').select('id, name');
      if (mounted) {
        setState(() {
          _clubs = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      // Игнорируем ошибки если клубов нет
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Введите название группы")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = supabase.auth.currentUser!.id;

      await supabase.from('groups').insert({
        'name': name,
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'is_private': _isPrivate,
        'club_id': _selectedClubId != null ? int.parse(_selectedClubId!) : null,
        'creator_id': uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Группа успешно создана!"),
            backgroundColor: Colors.green));
        
        // 🔥 ВОТ ЗДЕСЬ МАГИЯ: передаем true назад
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Ошибка: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text("Создать группу",
            style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold)),
        backgroundColor: _bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField("Название группы", _nameController),
                  const SizedBox(height: 15),
                  _inputField("Описание", _descController, lines: 3),
                  const SizedBox(height: 20),
                  const Text("Локация", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _inputField("Город / Район", _locationController,
                      icon: Icons.location_on),
                  const SizedBox(height: 20),
                  
                  // Выбор клуба
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: _inputColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClubId,
                        dropdownColor: _inputColor,
                        hint: Text("Привязка к клубу (необязательно)",
                            style: TextStyle(color: _textGrey)),
                        isExpanded: true,
                        style: TextStyle(color: _textWhite, fontSize: 16),
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child: Text("Без привязки",
                                  style: TextStyle(color: _textWhite))),
                          ..._clubs.map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['name'],
                                  style: TextStyle(color: _textWhite))))
                        ],
                        onChanged: (v) => setState(() => _selectedClubId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Приватность
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: _inputColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: Text("Приватная группа",
                          style: TextStyle(
                              color: _textWhite, fontWeight: FontWeight.bold)),
                      subtitle: Text("Вступление только по приглашению",
                          style: TextStyle(fontSize: 12, color: _textGrey)),
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                      activeColor: const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                      child: const Text("Создать группу",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller,
      {int lines = 1, IconData? icon}) {
    return TextField(
      controller: controller,
      maxLines: lines,
      style: TextStyle(color: _textWhite),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textGrey),
          filled: true,
          fillColor: _inputColor,
          prefixIcon: icon != null ? Icon(icon, color: _textGrey) : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16)),
    );
  }
}