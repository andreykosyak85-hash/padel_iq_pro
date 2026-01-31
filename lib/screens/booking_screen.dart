import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Состояние формы
  bool isNearMe = true; // "Рядом со мной"
  DateTime selectedDate = DateTime.now();
  final TextEditingController _clubController = TextEditingController();
  int _selectedTab = 0; // 0 = Reserva, 1 = Partidos

  // 📍 Выбор даты
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2979FF), // Цвет выбора
              onPrimary: Colors.white,
              surface: Color(0xFF10192B), // Фон календаря
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Играешь в Padel? 🎾",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // 1. ТАБЫ (Reserva / Partidos)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10192B),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  _buildTab("Бронирование", 0),
                  _buildTab("Матчи", 1),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. ВЫБОР ДАТЫ
            const Text("Когда?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF10192B),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70),
                    const SizedBox(width: 15),
                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. ГДЕ? (Клуб или Геолокация)
            const Text("Где?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            
            // Переключатель "Рядом / Вручную"
            Row(
              children: [
                ActionChip(
                  label: const Text("📍 Рядом со мной"),
                  backgroundColor: isNearMe ? const Color(0xFF2979FF) : const Color(0xFF10192B),
                  labelStyle: TextStyle(color: isNearMe ? Colors.white : Colors.grey),
                  onPressed: () => setState(() => isNearMe = true),
                  shape: const StadiumBorder(),
                ),
                const SizedBox(width: 10),
                ActionChip(
                  label: const Text("🔎 Найти клуб"),
                  backgroundColor: !isNearMe ? const Color(0xFF2979FF) : const Color(0xFF10192B),
                  labelStyle: TextStyle(color: !isNearMe ? Colors.white : Colors.grey),
                  onPressed: () => setState(() => isNearMe = false),
                  shape: const StadiumBorder(),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Если выбрано "Найти клуб" - показываем поле ввода
            if (!isNearMe)
              TextField(
                controller: _clubController,
                decoration: const InputDecoration(
                  hintText: "Введите название клуба...",
                  prefixIcon: Icon(Icons.search),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(child: Text("Используем вашу геолокацию для поиска ближайших кортов")),
                  ],
                ),
              ),

            const Spacer(),

            // КНОПКА ПОИСКА
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Логика поиска...
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поиск кортов...')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  shadowColor: const Color(0xFF2979FF).withOpacity(0.5),
                  elevation: 10,
                ),
                child: const Text("Найти игру", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1C2538) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: isActive ? Border.all(color: const Color(0xFF2979FF)) : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}