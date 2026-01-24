import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Доступ к supabase
import 'matches_screen.dart'; // <-- ТЕПЕРЬ МЫ ИДЕМ СЮДА

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  double _calculatedRating = 1.0;

  // Вопросы для определения уровня
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Как долго вы играете в падел?',
      'answers': [
        {'text': 'Первый раз', 'score': 1.0},
        {'text': 'Меньше месяца', 'score': 2.0},
        {'text': 'Полгода', 'score': 3.0},
        {'text': 'Более года', 'score': 4.5},
        {'text': 'Я профи (Тренер)', 'score': 6.0},
      ],
    },
    {
      'question': 'Как у вас с подачей?',
      'answers': [
        {'text': 'Часто в сетку / аут', 'score': 1.5},
        {'text': 'Просто ввожу мяч', 'score': 2.5},
        {'text': 'Могу направить в угол', 'score': 3.5},
        {'text': 'Сильная, крученая, точная', 'score': 5.0},
      ],
    },
    {
      'question': 'Игра у сетки (Volley)',
      'answers': [
        {'text': 'Боюсь выходить к сетке', 'score': 1.5},
        {'text': 'Отбиваю, но без атаки', 'score': 2.5},
        {'text': 'Забиваю простые мячи', 'score': 4.0},
        {'text': 'Агрессивная атака, x3/x4', 'score': 5.5},
      ],
    },
  ];

  void _answerQuestion(double score) {
    // Простая логика: усредняем рейтинг с каждым ответом
    if (_currentQuestionIndex == 0) {
      _calculatedRating = score;
    } else {
      _calculatedRating = (_calculatedRating + score) / 2;
    }

    setState(() {
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      _finishQuiz();
    }
  }

  // 🔥 САМОЕ ВАЖНОЕ: Сохраняем в Supabase и идем в Матчи
  Future<void> _finishQuiz() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Округляем рейтинг до 0.5 (например 3.2 -> 3.0, 3.4 -> 3.5)
      double finalRating = ((_calculatedRating * 2).round() / 2);
      if (finalRating < 1.0) finalRating = 1.0;
      if (finalRating > 7.0) finalRating = 7.0;

      // 2. Отправляем в базу данных
      await supabase.from('profiles').update({
        'rating': finalRating,
        // Сразу пропишем статы, равные общему рейтингу
        'stats': {
          'SMA': finalRating, 'DEF': finalRating, 'TAC': finalRating,
          'VOL': finalRating, 'LOB': finalRating, 'PHY': finalRating
        }
      }).eq('id', userId);

      if (mounted) {
        // 3. Переходим на ГЛАВНЫЙ ЭКРАН (MatchesScreen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MatchesScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Оценка уровня"), 
        backgroundColor: const Color(0xFF1C2538), 
        automaticallyImplyLeading: false // Убираем кнопку "Назад", чтобы не сбежали
      ),
      body: _currentQuestionIndex < _questions.length
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _questions[_currentQuestionIndex]['question'],
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ...(_questions[_currentQuestionIndex]['answers'] as List<Map<String, dynamic>>).map((answer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => _answerQuestion(answer['score']),
                        child: Text(answer['text'], style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    );
                  }),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()), // Крутим загрузку, пока сохраняем
    );
  }
}