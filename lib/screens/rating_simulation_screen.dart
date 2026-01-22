import 'package:flutter/material.dart';
import '../logic/rating_engine.dart'; // <--- ВОТ ЭТОТ ИМПОРТ ВАЖЕН

class RatingSimulationScreen extends StatefulWidget {
  final double currentRating;
  const RatingSimulationScreen({super.key, required this.currentRating});

  @override
  State<RatingSimulationScreen> createState() => _RatingSimulationScreenState();
}

class _RatingSimulationScreenState extends State<RatingSimulationScreen> {
  // Параметры матча
  double partnerRating = 2.5;
  double opponentRating = 2.5;
  double reliability = 1.0; // Идеальная надежность
  double stability = 1.0;   // Идеальная стабильность
  double groupTrust = 1.0;  // Официальный матч
  double formatWeight = 1.0; // Обычная игра
  int repetitionCount = 0;   // Первый раз с ними
  int gamesPlayed = 20;      // Опытный игрок

  // Результат расчета
  double? deltaWin;
  double? deltaLoss;

  void _calculate() {
    setState(() {
      // Расчет для ПОБЕДЫ
      deltaWin = RatingEngine.calculateAdvancedDelta(
        currentRating: widget.currentRating,
        partnerRating: partnerRating,
        opponentAvgRating: opponentRating,
        gamesPlayed: gamesPlayed,
        reliability: reliability,
        stability: stability,
        repetitionCount: repetitionCount,
        groupTrust: groupTrust,
        formatWeight: formatWeight,
        result: 1, // WIN
      );

      // Расчет для ПОРАЖЕНИЯ
      deltaLoss = RatingEngine.calculateAdvancedDelta(
        currentRating: widget.currentRating,
        partnerRating: partnerRating,
        opponentAvgRating: opponentRating,
        gamesPlayed: gamesPlayed,
        reliability: reliability,
        stability: stability,
        repetitionCount: repetitionCount,
        groupTrust: groupTrust,
        formatWeight: formatWeight,
        result: 0, // LOSS
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Новый рейтинг при победе
    double newRatingWin = widget.currentRating + (deltaWin ?? 0);
    // Новый рейтинг при поражении
    double newRatingLoss = widget.currentRating + (deltaLoss ?? 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Лаборатория Рейтинга 🧮')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            
            // --- НАСТРОЙКИ МАТЧА ---
            _buildSlider('Рейтинг Партнера', partnerRating, 1.0, 7.0, (v) => partnerRating = v),
            _buildSlider('Средний рейтинг Противников', opponentRating, 1.0, 7.0, (v) => opponentRating = v),
            const Divider(),
            _buildSlider('Надёжность игрока (Reliability)', reliability, 0.5, 1.0, (v) => reliability = v),
            _buildSlider('Антифарм (Игр подряд)', repetitionCount.toDouble(), 0, 10, (v) => repetitionCount = v.toInt()),
            _buildSlider('Вес Турнира (1.0 - 1.5)', formatWeight, 1.0, 1.5, (v) => formatWeight = v),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('РАССЧИТАТЬ ДЕЛЬТУ', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 30),

            // --- РЕЗУЛЬТАТЫ ---
            if (deltaWin != null) ...[
              const Text('Результаты расчета:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildResultCard('ПОБЕДА 🏆', deltaWin!, newRatingWin, Colors.green)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildResultCard('ПОРАЖЕНИЕ 💀', deltaLoss!, newRatingLoss, Colors.red)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '* Дельта учитывает вес партнера, антифарм и надежность.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Твой текущий:', style: TextStyle(fontSize: 16)),
          Text(
            widget.currentRating.toStringAsFixed(3), // ПОКАЗЫВАЕМ 3 ЗНАКА
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          divisions: (max - min) > 1 ? 100 : 10,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Widget _buildResultCard(String title, double delta, double newRating, Color color) {
    String sign = delta > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            '$sign${delta.toStringAsFixed(3)}', // ДЕЛЬТА (напр. +0.015)
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            'Новый: ${newRating.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}