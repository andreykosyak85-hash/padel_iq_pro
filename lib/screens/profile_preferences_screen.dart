import 'package:flutter/material.dart';

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() => _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  final List<String> weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  
  // Храним выбранное время для каждого дня: "Пн": ["Утро", "Вечер"]
  Map<String, List<String>> schedule = {};

  final List<String> timeSlots = ['Утро (07-12)', 'День (12-17)', 'Вечер (17-23)'];

  // Открыть выбор времени для конкретного дня
  void _openTimeSelector(String day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder( // Чтобы обновлять состояние внутри BottomSheet
          builder: (context, setSheetState) {
            List<String> currentSelections = schedule[day] ?? [];
            return Container(
              padding: const EdgeInsets.all(24),
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Когда играем в $day?", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: timeSlots.map((time) {
                      bool isSelected = currentSelections.contains(time);
                      return FilterChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (val) {
                          setSheetState(() {
                            if (val) {
                              currentSelections.add(time);
                            } else {
                              currentSelections.remove(time);
                            }
                            // Сохраняем в общую карту
                            schedule[day] = currentSelections;
                          });
                          // Обновляем основной экран тоже
                          setState(() {}); 
                        },
                        backgroundColor: const Color(0xFF1C2538),
                        selectedColor: const Color(0xFF2979FF),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                        checkmarkColor: Colors.white,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Мое расписание"), backgroundColor: Colors.transparent),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          String day = weekDays[index];
          List<String> times = schedule[day] ?? [];
          bool isActive = times.isNotEmpty;

          return Card(
            color: isActive ? const Color(0xFF1C2538) : const Color(0xFF10192B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: isActive ? const BorderSide(color: Color(0xFF2979FF), width: 1) : BorderSide.none,
            ),
            child: ListTile(
              onTap: () => _openTimeSelector(day),
              leading: CircleAvatar(
                backgroundColor: isActive ? const Color(0xFF2979FF) : Colors.white10,
                child: Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(isActive ? times.join(", ") : "Выходной", 
                style: TextStyle(color: isActive ? Colors.white : Colors.grey)
              ),
              trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Сохранить расписание"),
        ),
      ),
    );
  }
}