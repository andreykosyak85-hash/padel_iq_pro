import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 📊 Библиотека графиков

class ProfileScreen extends StatefulWidget {
  final double rating;
  const ProfileScreen({super.key, required this.rating});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedPeriod = '6M'; // По умолчанию полгода

  // 🔥 ДАННЫЕ ДЛЯ ГРАФИКА
  final Map<String, List<FlSpot>> _chartData = {
    '1M': [
      const FlSpot(0, 3.35), const FlSpot(1, 3.38), const FlSpot(2, 3.32),
      const FlSpot(3, 3.40), const FlSpot(4, 3.42), const FlSpot(5, 3.45),
    ],
    '6M': [
      const FlSpot(0, 2.90), const FlSpot(1, 3.05), const FlSpot(2, 2.95),
      const FlSpot(3, 3.15), const FlSpot(4, 3.30), const FlSpot(5, 3.45),
    ],
    'YTD': [
      const FlSpot(0, 2.5), const FlSpot(1, 2.8), const FlSpot(2, 3.0),
      const FlSpot(3, 3.2), const FlSpot(4, 3.4), const FlSpot(5, 3.55),
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Определяем цвет уровня
    Color accentColor;
    String statusText;
    if (widget.rating < 2.5) {
      accentColor = const Color(0xFF00C853); statusText = "ROOKIE";
    } else if (widget.rating < 4.5) {
      accentColor = const Color(0xFF2979FF); statusText = "AMATEUR";
    } else {
      accentColor = const Color(0xFFFF6D00); statusText = "PRO ELITE";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ОБНОВЛЕННАЯ ШИРОКАЯ ШАПКА 💎
            _buildNewHeader(accentColor, statusText),

            const SizedBox(height: 25),

            // 2. ПЕРЕКЛЮЧАТЕЛЬ ПЕРИОДА
            _buildPeriodSelector(accentColor),

            const SizedBox(height: 20),

            // 3. ГРАФИК
            _buildChartSection(accentColor),

            const SizedBox(height: 25),

            // 4. ДЕТАЛЬНАЯ СТАТИСТИКА
            _buildStatsGrid(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 🔥 НОВАЯ ШАПКА ---
  Widget _buildNewHeader(Color color, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        // Градиент сверху вниз (от цвета уровня к темному)
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15), // Легкий оттенок сверху
            const Color(0xFF0A0E21)  // Переход в фон
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)), // Убрали скругление для стиля "на весь экран"
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Аватарка с сиянием
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2), // Цветная рамка
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)], // Неоновое свечение
            ),
            child: const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF1C2538),
              backgroundImage: AssetImage('assets/logo.png'), 
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Информация (Имя и Статус)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ANDREY K.",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),

          // Рейтинг (Крупно справа)
          Column(
            children: [
              Text(
                widget.rating.toStringAsFixed(2),
                style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 20)]),
              ),
              const Text("RATING", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  // --- ОСТАЛЬНЫЕ ВИДЖЕТЫ (Без изменений) ---

  Widget _buildPeriodSelector(Color activeColor) {
    final periods = ['1M', '6M', 'YTD'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF1C2538), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: periods.map((period) {
          bool isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: isSelected ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(25)),
                child: Text(period, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(Color color) {
    List<FlSpot> data = _chartData[_selectedPeriod]!;
    double minY = data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.1;
    double maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
      height: 250,
      decoration: BoxDecoration(color: const Color(0xFF1C2538), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Прогресс ($_selectedPeriod)", style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                Icon(Icons.show_chart, color: color, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: minY, maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: data, isCurved: true, color: color, barWidth: 4, isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color)),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatTile("Винрейт", "75%", Icons.pie_chart, Colors.purpleAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatTile("Матчей", "24", Icons.sports_tennis, Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildStatTile("Серия", "5 Win", Icons.local_fire_department, Colors.orangeAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatTile("MVP", "8 раз", Icons.star, Colors.yellowAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C2538), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}