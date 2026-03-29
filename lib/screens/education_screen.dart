import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final lessons = [
    {
      'id': 'budgeting_101',
      'title': 'Budgeting 101',
      'content': 'How to create a simple monthly budget.',
    },
    {
      'id': 'saving_tips',
      'title': 'Saving Tips',
      'content': 'Small habits that grow your savings.',
    },
    {
      'id': 'avoiding_debt',
      'title': 'Avoiding Debt',
      'content': 'Practical tips to avoid unnecessary borrowing.',
    },
  ];

  static const _kDoneKey = 'sf_lessons_done_v1';
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _loadDone();
  }

  Future<void> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kDoneKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final list = List<String>.from(jsonDecode(jsonStr) as List<dynamic>);
      setState(() => _done = list.toSet());
    }
  }

  Future<void> _toggleDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_done.contains(id)) {
        _done.remove(id);
      } else {
        _done.add(id);
      }
    });
    await prefs.setString(_kDoneKey, jsonEncode(_done.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Modules')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (ctx, i) {
          final lesson = lessons[i];
          final id = lesson['id'] as String;
          final done = _done.contains(id);
          return Card(
            child: ListTile(
              title: Text(lesson['title'] as String),
              subtitle: Text(lesson['content'] as String),
              trailing: IconButton(
                icon: Icon(
                  done ? Icons.check_circle : Icons.circle_outlined,
                  color: done ? Colors.green : null,
                ),
                onPressed: () => _toggleDone(id),
              ),
            ),
          );
        },
      ),
    );
  }
}
