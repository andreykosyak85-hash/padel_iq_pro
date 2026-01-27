import 'package:flutter/material.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _neonOrange = const Color(0xFFFF5500);

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  
  // Контроллер для ввода названия клуба
  final TextEditingController _clubController = TextEditingController();
  
  // Выбранный формат (по умолчанию Friendly)
  String _selectedFormat = "Friendly"; 
  
  // Приватность
  bool _isPrivate = false;

  @override
  void dispose() {
    _clubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        title: const Text("Создать матч", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ВВОД КЛУБА
            const Text("Где играем?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _clubController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: _cardColor,
                hintText: "Название клуба (например, Central Padel)",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _neonOrange)),
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. ДАТА И ВРЕМЯ
            Row(
              children: [
                Expanded(
                  child: _buildOptionTile(Icons.calendar_month, "Дата", "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setState(() => _selectedDate = d);
                  }),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildOptionTile(Icons.access_time, "Время", _selectedTime.format(context), () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setState(() => _selectedTime = t);
                  }),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 3. ФОРМАТ ИГРЫ (ВЫПАДАЮЩИЙ СПИСОК)
            const Text("Формат игры", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFormat,
                  dropdownColor: _cardColor,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: ["Friendly", "Competitive", "Americano", "Mexicano", "Training"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedFormat = val!),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 4. ПРИВАТНОСТЬ
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isPrivate ? Colors.redAccent.withOpacity(0.5) : Colors.green.withOpacity(0.5))
              ),
              child: SwitchListTile(
                title: Text(_isPrivate ? "Закрытый матч" : "Публичный матч", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(_isPrivate ? "Вход только по приглашению" : "Виден всем игрокам в поиске", 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                value: _isPrivate,
                activeColor: Colors.white,
                activeTrackColor: Colors.redAccent,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.green,
                onChanged: (val) => setState(() => _isPrivate = val),
              ),
            ),

            const SizedBox(height: 40),

            // КНОПКА СОЗДАТЬ
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () {
                  // Пока просто показываем сообщение, сохранение в базу прикрутим позже
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Матч создан! Клуб: ${_clubController.text.isEmpty ? 'Не указан' : _clubController.text}"), 
                      backgroundColor: Colors.green
                    )
                  );
                  Navigator.pop(context);
                }, 
                child: const Text("Опубликовать матч", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey, size: 16),
                const SizedBox(width: 5),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}