import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

// --- 1. МОДЕЛЬ ДАННЫХ (Структура вопроса) ---
class Question {
  final String text;
  final double weight; // Вес вопроса (0.15, 0.20 и т.д.)
  final List<Answer> answers;

  Question({required this.text, required this.weight, required this.answers});
}

class Answer {
  final String text;
  final double value; // Баллы от 0 до 3

  Answer(this.text, this.value);
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  double _totalSoftScore = 0.0; // Накопленный взвешенный балл (0.0 - 3.0)

  // --- 2. БАЗА ВОПРОСОВ (Твои отфильтрованные вопросы) ---
  final List<Question> _questions = [
    // ❓ Вопрос 1 (Вес 15%)
    Question(
      text: 'Как давно ты играешь в падел?',
      weight: 0.15,
      answers: [
        Answer('Меньше 3 месяцев', 0.0),
        Answer('3–12 месяцев', 1.0),
        Answer('1–3 года', 2.0),
        Answer('3+ лет', 3.0),
      ],
    ),
    // ❓ Вопрос 2 (Вес 20%)
    Question(
      text: 'С кем ты обычно играешь?',
      weight: 0.20,
      answers: [
        Answer('Новички', 0.0),
        Answer('Любители', 1.0),
        Answer('Уверенные игроки', 2.0),
        Answer('Турнирные игроки', 3.0),
      ],
    ),
    // ❓ Вопрос 3 (Вес 15%)
    Question(
      text: 'Как ты чувствуешь себя у сетки (Volley)?',
      weight: 0.15,
      answers: [
        Answer('Избегаю', 0.0),
        Answer('Иногда выхожу', 1.0),
        Answer('Комфортно', 2.0),
        Answer('Моя сильная сторона', 3.0),
      ],
    ),
    // ❓ Вопрос 4 (Вес 20%)
    Question(
      text: 'Понимаешь ли ты тактику (Bandeja, Vibora, выход)?',
      weight: 0.20,
      answers: [
        Answer('Нет', 0.0),
        Answer('Частично', 1.0),
        Answer('Да', 2.0),
        Answer('Использую осознанно', 3.0),
      ],
    ),
    // ❓ Вопрос 5 (Вес 15%)
    Question(
      text: 'Твой турнирный опыт?',
      weight: 0.15,
      answers: [
        Answer('Никогда', 0.0),
        Answer('Внутриклубные', 1.0),
        Answer('Региональные', 2.0),
        Answer('Национальные', 3.0),
      ],
    ),
    // ❓ Вопрос 6 (Вес 15%)
    Question(
      text: 'Как часто ты играешь сейчас?',
      weight: 0.15,
      answers: [
        Answer('1 раз в месяц', 0.0),
        Answer('1 раз в неделю', 1.0),
        Answer('2–3 раза в неделю', 2.0),
        Answer('4+ раз в неделю', 3.0),
      ],
    ),
  ];

  // --- 3. ЛОГИКА РАСЧЕТА (Soft Score) ---
  void _answerQuestion(double answerValue) {
    // Формула: Score += (Ответ * Вес вопроса)
    double points = answerValue * _questions[_currentQuestionIndex].weight;
    
    setState(() {
      _totalSoftScore += points;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    // 1. Конвертация SoftScore (0-3) в Рейтинг Падела (1.0 - 7.0)
    // Формула: 1.0 + (SoftScore * 2)
    double finalRating = 1.0 + (_totalSoftScore * 2);

    // Округляем до сотых (например 3.45)
    finalRating = double.parse(finalRating.toStringAsFixed(2));

    print("Soft Score: $_totalSoftScore"); // Для отладки
    print("Final Rating: $finalRating");

    // 2. ЗАЩИТА (PRO CHECK)
    // Если рейтинг выше 5.5, срезаем и требуем тренера
    if (finalRating > 5.5) {
      _showProRestrictionDialog(finalRating);
    } else {
      _navigateToDashboard(finalRating);
    }
  }

  void _showProRestrictionDialog(double calculatedRating) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Вау! Высокий уровень 🏆'),
        content: Text(
          'Ваши ответы соответствуют рейтингу $calculatedRating.\n\n'
          'Уровни выше 5.5 (Pro) требуют подтверждения сертифицированным тренером Padel MVP.\n\n'
          'Пока мы установим ваш рейтинг: 5.50.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToDashboard(5.5);
            },
            child: const Text('Принять 5.5', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard(double rating) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialRating: rating),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Шаг ${_currentQuestionIndex + 1} из ${_questions.length}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Прогресс бар
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 40),
            
            // Текст вопроса
            Text(
              question.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Кнопки ответов
            ...question.answers.map((answer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(answer.value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft, // Текст слева
                  ),
                  child: Row(
                    children: [
                      // Кружочек выбора (для красоты)
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Текст ответа
                      Expanded(
                        child: Text(
                          answer.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}