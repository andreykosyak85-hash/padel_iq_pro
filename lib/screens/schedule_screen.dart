import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  
  // Храним выбранное время
  Map<String, List<String>> schedule = {};

  final List<String> timeSlots = ['Утро (07-12)', 'День (12-17)', 'Вечер (17-23)'];

  void _openTimeSelector(String day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22), // Темный фон шторки
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<String> currentSelections = schedule[day] ?? [];
            return Container(
              padding: const EdgeInsets.all(24),
              height: 350,
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
                            schedule[day] = currentSelections;
                          });
                          setState(() {}); // Обновляем основной экран
                        },
                        backgroundColor: const Color(0xFF0D1117),
                        selectedColor: const Color(0xFF2F80ED),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                        checkmarkColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      backgroundColor: const Color(0xFF0D1117), // Наш общий темный фон
      appBar: AppBar(
        title: const Text("Мое расписание", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          String day = weekDays[index];
          List<String> times = schedule[day] ?? [];
          bool isActive = times.isNotEmpty;

          return Card(
            color: isActive ? const Color(0xFF1F6FEB).withOpacity(0.1) : const Color(0xFF161B22),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: isActive ? const BorderSide(color: Color(0xFF2F80ED), width: 1) : BorderSide.none,
            ),
            child: ListTile(
              onTap: () => _openTimeSelector(day),
              leading: CircleAvatar(
                backgroundColor: isActive ? const Color(0xFF2F80ED) : Colors.white10,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F80ED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () {
            // Тут можно добавить сохранение в Supabase
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Расписание сохранено (локально)")));
          },
          child: const Text("Сохранить", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}