import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Обязательно проверь наличие этого файла!

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // --- 📊 СОСТОЯНИЕ ИГРОКА ---
  double myRating = 3.40; 
  Map<String, double> myStats = {
    'SMA': 3.8, 'DEF': 3.1, 'TAC': 3.4, 'VOL': 3.5, 'LOB': 3.2, 'PHY': 3.9,
  };

  // --- 📋 ДАННЫЕ ФОРМАТОВ ---
  final List<String> gameFormats = ['MATCH', 'AMERICANO', 'MEXICANO', 'WINNER_COURT', 'TOURNAMENT'];

  // --- 📋 СПИСОК МАТЧЕЙ ---
  List<Map<String, dynamic>> matches = [
    {
      'id': 1, 'type': 'MATCH', 'title': 'Утренний спарринг', 'time': '09:00',
      'minRating': 1.0, 'maxRating': 7.0, 'isPublic': true
    },
  ];

  // --- 🛠️ МЕТОД 1: СОЗДАНИЕ ИГРЫ (С RangeSlider и Форматами) ---
  void _showCreateMatchDialog() {
    String title = 'Новая игра';
    String selectedFormat = 'MATCH'; 
    RangeValues currentRange = const RangeValues(1.0, 7.0);
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF10192B), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              title: const Text('Создать игру', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Название', labelStyle: TextStyle(color: Colors.grey)),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 20),
                    const Align(alignment: Alignment.centerLeft, child: Text('Формат игры:', style: TextStyle(color: Colors.white, fontSize: 14))),
                    DropdownButton<String>(
                      value: selectedFormat,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1C2538),
                      style: const TextStyle(color: Colors.white),
                      items: gameFormats.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (val) => setDialogState(() => selectedFormat = val!),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(isPublic ? "🌎 Публичная" : "🔒 Частная", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      value: isPublic,
                      activeColor: const Color(0xFF2979FF),
                      onChanged: (val) => setDialogState(() => isPublic = val),
                    ),
                    const SizedBox(height: 20),
                    const Align(alignment: Alignment.centerLeft, child: Text('Уровень допуска:', style: TextStyle(color: Colors.white, fontSize: 14))),
                    RangeSlider(
                      values: currentRange,
                      min: 1.0, max: 7.0, divisions: 12,
                      activeColor: const Color(0xFF2979FF),
                      labels: RangeLabels(currentRange.start.toStringAsFixed(1), currentRange.end.toStringAsFixed(1)),
                      onChanged: (val) => setDialogState(() => currentRange = val),
                    ),
                    Text('${currentRange.start.toStringAsFixed(1)} - ${currentRange.end.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF2979FF))),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    setState(() {
                      matches.insert(0, {
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'type': selectedFormat,
                        'title': title,
                        'time': 'Сегодня',
                        'minRating': currentRange.start,
                        'maxRating': currentRange.end,
                        'isPublic': isPublic,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Создать', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 🛠️ МЕТОД 2: ТВОЙ КОД ОПРОСА (ИНТЕГРИРОВАНО БЕЗ ИЗМЕНЕНИЙ) ---
  void _showSmartResultDialog() {
    List<String> selectedSkills = [];
    bool isWin = true;

    final Map<String, String> skillTags = {
      'SMA': 'Смэш (Smash)',
      'DEF': 'Защита (Defense)',
      'TAC': 'Тактика (Tactics)',
      'VOL': 'Слёта (Volley)',
      'LOB': 'Свеча (Lob)',
      'PHY': 'Физика (Physical)',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Color themeColor = isWin ? Colors.green : Colors.redAccent;
            String questionText = isWin ? "Что сегодня тащило игру?" : "Из-за чего проиграли?";

            return AlertDialog(
              backgroundColor: const Color(0xFF1C2538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Итог матча", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isWin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isWin ? Colors.green.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(color: isWin ? Colors.green : Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.green),
                                  Text("ПОБЕДА", style: TextStyle(color: isWin ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isWin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isWin ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(color: !isWin ? Colors.redAccent : Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.thumb_down, color: Colors.redAccent),
                                  Text("ПОРАЖЕНИЕ", style: TextStyle(color: !isWin ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildScoreBox("6"), const SizedBox(width: 10), _buildScoreBox("4")]),
                    const SizedBox(height: 20),
                    Text(questionText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: skillTags.entries.map((entry) {
                        final isSelected = selectedSkills.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setDialogState(() {
                              if (selected) selectedSkills.add(entry.key);
                              else selectedSkills.remove(entry.key);
                            });
                          },
                          backgroundColor: const Color(0xFF0A0E21),
                          selectedColor: themeColor.withOpacity(0.3),
                          labelStyle: TextStyle(color: isSelected ? themeColor : Colors.grey),
                          checkmarkColor: themeColor,
                          side: BorderSide(color: isSelected ? themeColor : Colors.transparent),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isWin) {
                        myRating = (myRating + 0.05).clamp(1.0, 7.0);
                        for (String key in selectedSkills) {
                          if (myStats.containsKey(key)) myStats[key] = (myStats[key]! + 0.1).clamp(0.0, 9.9);
                        }
                      } else {
                        myRating = (myRating - 0.05).clamp(1.0, 7.0);
                        for (String key in selectedSkills) {
                          if (myStats.containsKey(key)) myStats[key] = (myStats[key]! - 0.1).clamp(0.0, 9.9);
                        }
                      }
                      myStats['PHY'] = (myStats['PHY']! + (isWin ? 0.05 : 0.02)).clamp(0.0, 9.9);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: const Text("Сохранить результат", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreBox(String score) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)));

  // --- 🎨 ВИЗУАЛ: FUT-КАРТОЧКА (С ФУНКЦИЕЙ ФОТО) ---
  Widget _buildFUTCard() {
    return Center(
      child: Container(
        width: 280, height: 420,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFF42A5F5), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.8), width: 5),
          boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 25)],
        ),
        child: Stack(children: [
          Positioned(top: 30, left: 20, child: Text(myRating.toStringAsFixed(2), style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Color(0xFF0A0E21)))),
          // Кнопка ЗАГРУЗИТЬ ФОТО (Интерактивная область)
          Positioned(top: 60, right: 10, left: 50, bottom: 130, child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Камера/Галерея пока в разработке"))),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_add_alt_1, size: 60, color: Colors.black26), Text("ЗАГРУЗИТЬ\nФОТО", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold))]),
            ),
          )),
          Positioned(bottom: 110, left: 0, right: 0, child: Center(child: Text("ANDREY K.", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0A0E21))))),
          Positioned(bottom: 25, left: 25, right: 25, child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatItem(myStats['VOL']!, "VOL"), _buildStatItem(myStats['SMA']!, "SMA")]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatItem(myStats['LOB']!, "LOB"), _buildStatItem(myStats['DEF']!, "DEF")]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatItem(myStats['PHY']!, "PHY"), _buildStatItem(myStats['TAC']!, "TAC")]),
          ]))
        ]),
      ),
    );
  }

  Widget _buildStatItem(double val, String label) => Row(children: [Text(val.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A0E21))), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0A0E21)))]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateMatchDialog, backgroundColor: const Color(0xFF2979FF), child: const Icon(Icons.add, color: Colors.white)),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 10),
          _buildFUTCard(),
          const SizedBox(height: 30),
          ListView.builder(
            padding: const EdgeInsets.all(16), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) => Card(
              color: const Color(0xFF1C2538), margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.sports_tennis, color: Colors.blue),
                title: Text(matches[index]['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("${matches[index]['type']} • ${matches[index]['time']}", style: const TextStyle(color: Colors.grey)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(chatTitle: matches[index]['title'])))),
                  ElevatedButton(onPressed: _showSmartResultDialog, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF)), child: const Text("Счёт")),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}