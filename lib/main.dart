import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/habits/state/habits_model.dart';
import 'features/habits/presentation/habits_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HabitsModel()..load(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const HabitsScreen(),
    );
  }
}
