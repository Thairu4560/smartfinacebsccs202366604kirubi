import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final questions = [
    {
      'q': 'What is a budget?',
      'options': ['Plan for spending', 'Investment'],
      'a': 0,
    },
    {
      'q': 'Is saving regularly important?',
      'options': ['Yes', 'No'],
      'a': 0,
    },
  ];

  int _index = 0;
  int _score = 0;
  final Map<int, int> _answers = {};

  static const _kBestKey = 'sf_quiz_best_v1';
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _best = prefs.getInt(_kBestKey) ?? 0);
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (_score > _best) await prefs.setInt(_kBestKey, _score);
  }

  void _submitAnswer(int choice) {
    final q = questions[_index];
    final correct = q['a'] as int;
    if (choice == correct) _score++;
    _answers[_index] = choice;
    if (_index < questions.length - 1) {
      setState(() => _index++);
    } else {
      _saveBest();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quiz Complete'),
          content: Text(
            'Score: $_score / ${questions.length}\nBest: ${_best > _score ? _best : _score}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) {
        setState(() {
          _index = 0;
          _score = 0;
          _answers.clear();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[_index];
    final opts = q['options'] as List<String>;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_index + 1} of ${questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(q['q'] as String, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ...List.generate(opts.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(i),
                  child: Text(opts[i]),
                ),
              );
            }),
            const Spacer(),
            Text('Best: $_best'),
          ],
        ),
      ),
    );
  }
}
