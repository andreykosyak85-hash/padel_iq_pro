import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  // --- ЦВЕТА ---
  final Color _bgDark = const Color(0xFF0D1117);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _neonOrange = const Color(0xFFFF5500);
  final Color _neonGreen = const Color(0xFFccff00);
  final Color _neonCyan = const Color(0xFF00E5FF);

  // --- КОНТРОЛЛЕРЫ И ПЕРЕМЕННЫЕ ---
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _selectedType = 'Friendly';
  double _selectedLevel = 2.5;
  bool _isLoading = false;

  final List<String> _matchTypes = ['Friendly', 'Americano', 'Competitive', 'Training'];

  // --- ЛОГИКА ---

  // Текст для уровня
  String _getLevelLabel(double level) {
    if (level >= 5.5) return "Cat 1 (Pro)";
    if (level >= 4.5) return "Cat 2 (Advanced)";
    if (level >= 3.5) return "Cat 3 (Interm +)";
    if (level >= 2.5) return "Cat 4 (Intermediate)";
    return "Cat 5 (Beginner)";
  }

  // Цвет слайдера
  Color _getLevelColor(double level) {
    if (level >= 4.5) return _neonOrange;
    if (level >= 3.5) return _neonCyan;
    return _neonGreen;
  }

  // Выбор ДАТЫ
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _neonGreen,
              onPrimary: Colors.black,
              surface: _cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Выбор ВРЕМЕНИ
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _neonGreen,
              onPrimary: Colors.black,
              surface: _cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // СОЗДАНИЕ МАТЧА (Исправлено: одна функция с авто-заголовком)
  Future<void> _createMatch() async {
    final location = _locationController.text.trim();

    if (location.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заполните: Клуб, Дату и Время"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      // Формируем дату и время
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

      // 🔥 АВТО-ЗАГОЛОВОК
      final autoTitle = "$_selectedType Match";

      await Supabase.instance.client.from('matches').insert({
        'creator_id': user?.id,
        'title': autoTitle, // Поле, которого не хватало
        'location': location,
        'date': dateStr,
        'time': timeStr,
        'type': _selectedType,
        'level_min': _selectedLevel,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Матч создан! 🎾"), backgroundColor: _neonGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red),
        );
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Создать матч", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ВЫБОР КЛУБА
            const Text("Где играем?", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Название клуба (напр. Central Club)",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: _cardColor,
                prefixIcon: Icon(Icons.location_on, color: _neonGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 25),

            // 2. ДАТА И ВРЕМЯ
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Дата", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: _neonCyan, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDate == null ? "Выбрать" : DateFormat('dd.MM').format(_selectedDate!),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Время", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: _neonOrange, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _selectedTime == null ? "Выбрать" : _selectedTime!.format(context),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 3. ТИП ИГРЫ
            const Text("Формат игры", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _matchTypes.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _selectedType = type),
                  selectedColor: _neonGreen,
                  backgroundColor: _cardColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // 4. УРОВЕНЬ (Слайдер)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Уровень игроков", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(_selectedLevel.toString(), style: TextStyle(color: _getLevelColor(_selectedLevel), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text(
                    _getLevelLabel(_selectedLevel),
                    style: TextStyle(color: _getLevelColor(_selectedLevel), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _getLevelColor(_selectedLevel),
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: Colors.white,
                      overlayColor: _getLevelColor(_selectedLevel).withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _selectedLevel,
                      min: 1.0,
                      max: 7.0,
                      divisions: 12,
                      onChanged: (val) => setState(() => _selectedLevel = val),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Beginner", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text("Pro", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 5. КНОПКА СОЗДАТЬ
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: _neonGreen.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Опубликовать матч", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}