import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Для supabase

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({super.key});

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen> {
  // Параметры паутинки (FIFA Style)
  double _smash = 50;
  double _volley = 50;
  double _lob = 50;
  double _defense = 50;
  double _speed = 50;
  double _power = 50;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStats(); // Подгружаем текущие цифры, чтобы не начинать с нуля
  }

  Future<void> _loadCurrentStats() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select('stats')
          .eq('id', uid)
          .single();

      if (profile['stats'] != null) {
        final Map<String, dynamic> loadedStats = profile['stats'];
        if (mounted) {
          setState(() {
            _smash = (loadedStats['SMA'] ?? 50).toDouble();
            _volley = (loadedStats['VOL'] ?? 50).toDouble();
            _lob = (loadedStats['LOB'] ?? 50).toDouble();
            _defense = (loadedStats['DEF'] ?? 50).toDouble();
            _speed = (loadedStats['SPD'] ?? 50).toDouble();
            _power = (loadedStats['PWR'] ?? 50).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint("Ошибка загрузки статов: $e");
    }
  }

  Future<void> _submitAnalysis() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // Сохраняем все скиллы в одном JSON объекте в колонку stats
      await supabase.from('profiles').update({
        'stats': {
          'SMA': _smash.toInt(),
          'VOL': _volley.toInt(),
          'LOB': _lob.toInt(),
          'DEF': _defense.toInt(),
          'SPD': _speed.toInt(),
          'PWR': _power.toInt(),
        }
      }).eq('id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Паутинка обновлена! 🕸️🔥")),
        );
        // Возвращаем true чтобы сигнализировать успех
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0D1117);
    const neonGreen = Color(0xFFccff00);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        title: const Text("Оценка навыков", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Как ты проявил себя в этом матче?",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Оцени свои удары, чтобы обновить карточку игрока.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            _buildSlider("💥 SMA (Смэш)", _smash, Colors.orange, (v) => setState(() => _smash = v)),
            _buildSlider("🎾 VOL (С лёта)", _volley, Colors.blue, (v) => setState(() => _volley = v)),
            _buildSlider("🏹 LOB (Свеча)", _lob, Colors.purple, (v) => setState(() => _lob = v)),
            _buildSlider("🛡️ DEF (Защита)", _defense, Colors.red, (v) => setState(() => _defense = v)),
            _buildSlider("⚡ SPD (Скорость)", _speed, neonGreen, (v) => setState(() => _speed = v)),
            _buildSlider("💪 PWR (Сила)", _power, Colors.yellow, (v) => setState(() => _power = v)),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitAnalysis,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Обновить профиль", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(value.toInt().toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0, 
            max: 99, 
            divisions: 99,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}