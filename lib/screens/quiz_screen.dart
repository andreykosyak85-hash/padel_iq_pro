import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  double _calculatedRating = 1.0;

  // Вопросы (я чуть подкрутил баллы, чтобы было интереснее)
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Вы когда-нибудь играли в Падел?',
      'answers': [
        {'text': 'Никогда', 'score': 1.0},
        {'text': 'Пару раз', 'score': 2.0},
        {'text': 'Играю регулярно', 'score': 3.0},
        {'text': 'Я профи / Тренер', 'score': 6.0}, // Тут даем много, но в конце проверим!
      ],
    },
    {
      'question': 'Играли ли вы в большой теннис?',
      'answers': [
        {'text': 'Нет', 'score': 0.0},
        {'text': 'Любитель', 'score': 0.5},
        {'text': 'Профессионал (ATP/ITF)', 'score': 1.5},
      ],
    },
    {
      'question': 'Как у вас с ударами от стекла?',
      'answers': [
        {'text': 'Что это?', 'score': 0.0},
        {'text': 'Сложно', 'score': 0.0},
        {'text': 'Уверенно возвращаю', 'score': 0.5},
        {'text': 'Атакую от стекла (Bajada)', 'score': 1.0},
      ],
    },
  ];

  void _answerQuestion(double scoreToAdd) {
    setState(() {
      if (_currentQuestionIndex == 0) {
        _calculatedRating = scoreToAdd;
      } else {
        _calculatedRating += scoreToAdd;
      }
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    // 1. Ограничение снизу (не меньше 1.0)
    if (_calculatedRating < 1.0) _calculatedRating = 1.0;

    // 2. ЗАЩИТА ОТ "САМОЗВАНЦЕВ" 🛡️
    // Если набрал больше 5.5 — срезаем и требуем проверку
    if (_calculatedRating > 5.5) {
      _showProRestrictionDialog();
    } else {
      // Если рейтинг обычный — пропускаем сразу
      _navigateToDashboard(_calculatedRating);
    }
  }

  // Всплывающее окно для "Профи"
  void _showProRestrictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Нельзя закрыть, нажав мимо
      builder: (context) => AlertDialog(
        title: const Text('Вау! Профессиональный уровень? 🏆'),
        content: const Text(
          'Ваши ответы указывают на рейтинг выше 6.0.\n\n'
          'По правилам Padel MVP, уровни 6.0–7.0 присваиваются ТОЛЬКО после аттестации сертифицированным тренером.\n\n'
          'Пока мы установим вам максимальный любительский рейтинг: 5.5.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрываем окно
              _navigateToDashboard(5.5); // Идем с рейтингом 5.5
            },
            child: const Text('Понятно, согласен', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Оценка уровня'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Убираем кнопку "Назад"
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 40),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...(question['answers'] as List<Map<String, dynamic>>).map((answer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(answer['score']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    answer['text'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}