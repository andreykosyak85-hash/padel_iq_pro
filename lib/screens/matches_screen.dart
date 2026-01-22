import 'package:flutter/material.dart';
import 'tournament_screen.dart';
import '../logic/rating_engine.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // 📊 1. ЖИВЫЕ ДАННЫЕ ИГРОКА
  double myRating = 3.40; 
  bool _hasCustomPhoto = false;

  // Реальные параметры (Start Stats)
  Map<String, double> myStats = {
    'VOL': 3.5, // Volea (Слёта)
    'SMA': 3.8, // Smash (Смэш)
    'LOB': 3.2, // Globo (Свеча)
    'DEF': 3.1, // Defense (Защита)
    'PHY': 3.9, // Physical (Физика)
    'TAC': 3.4, // Tactics (Тактика)
  };

  // 🔥 СТИЛИ КАРТОЧКИ (FUT Style)
  Map<String, dynamic> _getCardStyle(double rating) {
    if (rating < 2.5) {
      return {
        'status': 'ROOKIE',
        'colors': [const Color(0xFF8D6E63), const Color(0xFF5D4037)], 
        'textColor': Colors.white,
        'borderColor': const Color(0xFFA1887F),
      };
    } else if (rating < 4.5) {
      return {
        'status': 'AMATEUR',
        'colors': [const Color(0xFFE3F2FD), const Color(0xFF90CAF9), const Color(0xFF42A5F5)], 
        'textColor': const Color(0xFF10192B),
        'borderColor': Colors.white,
      };
    } else {
      return {
        'status': 'PRO',
        'colors': [const Color(0xFFFFD54F), const Color(0xFFFF6F00)], 
        'textColor': Colors.black,
        'borderColor': const Color(0xFFFFE082),
      };
    }
  }

  List<Map<String, dynamic>> matches = [
    {'id': 1, 'type': 'MATCH', 'title': 'Утренний спарринг', 'time': '09:00', 'court': 'Корт №3', 'price': '800₽'},
    {'id': 2, 'type': 'AMERICANO', 'title': 'Дневной турнир', 'time': '14:00', 'court': 'Корт №1', 'price': '1500₽'},
  ];

  // --- ЛОГИКА ОБНОВЛЕНИЯ СТАТИСТИКИ ---

  void _handleMatchAction(int index) {
    // Открываем диалог результата с оценкой навыков
    _showSmartResultDialog();
  }

  void _showSmartResultDialog() {
    // Временный список выбранных тегов
    List<String> selectedSkills = [];
    bool isWin = true; // По умолчанию считаем, что победа

    // Теги (Названия навыков)
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
            // Цвет интерфейса зависит от результата
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
                    // 1. ПЕРЕКЛЮЧАТЕЛЬ ПОБЕДА / ПОРАЖЕНИЕ
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
                
                    // 2. СЧЕТ (Просто визуально)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScoreBox("6"), const SizedBox(width: 10),
                        _buildScoreBox("4"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // 3. ВЫБОР ФАКТОРОВ
                    Text(questionText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
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
                          // Если победа - синие фишки, если поражение - красные
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Отмена", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // ЛОГИКА ОБНОВЛЕНИЯ СТАТИСТИКИ
                      if (isWin) {
                        // 🟢 ПОБЕДА: Рейтинг растет
                        myRating = (myRating + 0.05).clamp(1.0, 7.0);
                        // Выбранные навыки растут (Нас похвалили)
                        for (String key in selectedSkills) {
                          if (myStats.containsKey(key)) {
                            myStats[key] = (myStats[key]! + 0.1).clamp(0.0, 9.9);
                          }
                        }
                      } else {
                        // 🔴 ПОРАЖЕНИЕ: Рейтинг падает
                        myRating = (myRating - 0.05).clamp(1.0, 7.0);
                        // Выбранные навыки ПАДАЮТ (Это были наши ошибки)
                        for (String key in selectedSkills) {
                          if (myStats.containsKey(key)) {
                            myStats[key] = (myStats[key]! - 0.1).clamp(0.0, 9.9);
                          }
                        }
                      }
                      
                      // Физика растет всегда (мы же бегали), но при поражении меньше
                      double phyBonus = isWin ? 0.05 : 0.02;
                      myStats['PHY'] = (myStats['PHY']! + phyBonus).clamp(0.0, 9.9);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isWin ? "Победа! Рейтинг UP 📈" : "Опыт получен. Рейтинг DOWN 📉"),
                        backgroundColor: isWin ? Colors.green : Colors.redAccent,
                      ),
                    );
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
  Widget _buildScoreBox(String value) {
    return Container(
      width: 50, height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  // --- ФОТО (Как было) ---
  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10192B),
      builder: (context) => Container(
        height: 150,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Загрузить фото игрока", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () { setState(() => _hasCustomPhoto = true); Navigator.pop(context); },
                  icon: const Icon(Icons.camera_alt), label: const Text("Камера"),
                ),
                ElevatedButton.icon(
                  onPressed: () { setState(() => _hasCustomPhoto = false); Navigator.pop(context); },
                  icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Удалить", style: TextStyle(color: Colors.red)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Padel MVP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Тут будет создание матча
        backgroundColor: const Color(0xFF2979FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(child: _buildFUTCard()), 
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(alignment: Alignment.centerLeft, child: Text("Ближайшие игры", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) => _buildMatchCard(matches[index], index),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 🏆 КАРТОЧКА ИГРОКА (Обновленная)
  Widget _buildFUTCard() {
    final style = _getCardStyle(myRating);
    final List<Color> bgColors = style['colors'];
    final Color textColor = style['textColor'];
    final Color borderColor = style['borderColor'];

    return Container(
      width: 300, height: 450, 
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bgColors),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [BoxShadow(color: bgColors.last.withOpacity(0.6), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          // 1. РЕЙТИНГ
          Positioned(
            top: 25, left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ЖИВОЙ РЕЙТИНГ
                Text(myRating.toStringAsFixed(2), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: textColor)),
                Text(style['status'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7))),
                const SizedBox(height: 10),
                Icon(Icons.flag, color: textColor, size: 28),
              ],
            ),
          ),
          // 2. ФОТО
          Positioned(
            top: 50, right: 20, left: 20, bottom: 140, 
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: textColor.withOpacity(0.3), width: 2),
                ),
                child: _hasCustomPhoto
                    ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/logo.png', fit: BoxFit.contain)) 
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1, size: 50, color: textColor.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          Text("ЗАГРУЗИТЬ\nФОТО", textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ),
          // 3. ИМЯ
          Positioned(
            bottom: 100, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.black.withOpacity(0.15),
              child: Center(
                child: Text("ANDREY K.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
              ),
            ),
          ),
          // 4. ЖИВЫЕ ХАРАКТЕРИСТИКИ (Берутся из myStats)
          Positioned(
            bottom: 25, left: 25, right: 25,
            child: Column(
              children: [
                Container(height: 2, color: textColor.withOpacity(0.3)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildFutStat(myStats['VOL']!, "VOL", textColor),
                  _buildFutStat(myStats['SMA']!, "SMA", textColor)
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildFutStat(myStats['LOB']!, "LOB", textColor),
                  _buildFutStat(myStats['DEF']!, "DEF", textColor)
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildFutStat(myStats['PHY']!, "PHY", textColor),
                  _buildFutStat(myStats['TAC']!, "TAC", textColor)
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutStat(double val, String label, Color color) {
    return SizedBox(
      width: 90,
      child: Row(
        children: [
          // Отображаем живое число с 1 знаком после запятой
          Text(val.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF151A30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF2979FF).withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.sports_tennis, color: Color(0xFF2979FF)),
        ),
        title: Text(match['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(match['time'], style: const TextStyle(color: Colors.grey)),
        trailing: ElevatedButton(
          onPressed: () => _handleMatchAction(index), // Открываем диалог результата
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), foregroundColor: Colors.white),
          child: const Text("Ввести счет"),
        ),
      ),
    );
  }
}