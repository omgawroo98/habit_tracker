import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Habit {
  final String id;
  final String name;
  final int targetPerWeek;
  final Set<String> completions; // yyyy-MM-dd keys
  final int colorValue;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.targetPerWeek,
    required this.completions,
    required this.colorValue,
    required this.createdAt,
  });

  bool isCompletedOn(DateTime date) => completions.contains(_dateKey(date));

  int get streak {
    var day = _normalize(DateTime.now());
    var count = 0;
    while (isCompletedOn(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  int completionsWithinDays(int days) {
    final today = _normalize(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    return completions.where((raw) {
      final date = _parseDateKey(raw);
      return !_isBeforeDay(date, start) && !_isAfterDay(date, today);
    }).length;
  }

  Habit copyWith({
    String? name,
    int? targetPerWeek,
    Set<String>? completions,
    int? colorValue,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      completions: completions ?? this.completions,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawCompletions = (json['completions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      targetPerWeek: json['targetPerWeek'] as int? ?? 7,
      completions: rawCompletions,
      colorValue: json['colorValue'] as int? ?? 0xFF26A69A,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetPerWeek': targetPerWeek,
      'completions': completions.toList(),
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class HabitsModel extends ChangeNotifier {
  static const _storageKey = 'habits_data_v1';
  static const List<int> palette = [
    0xFF26A69A,
    0xFF7E57C2,
    0xFF42A5F5,
    0xFFEF6C00,
    0xFF66BB6A,
    0xFFF06292,
    0xFF5C6BC0,
  ];

  final List<Habit> _habits = [];
  SharedPreferences? _prefs;
  bool _isLoading = true;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;

  int get completedTodayCount =>
      _habits.where((h) => h.isCompletedOn(DateTime.now())).length;

  int get totalCheckInsLast7Days =>
      _habits.fold(0, (sum, h) => sum + h.completionsWithinDays(7));

  double get averageWeeklyProgress {
    if (_habits.isEmpty) return 0;
    final planned = _habits.fold<int>(0, (sum, h) => sum + h.targetPerWeek);
    final actual =
        _habits.fold<int>(0, (sum, h) => sum + h.completionsWithinDays(7));
    if (planned == 0) return 0;
    return (actual / planned).clamp(0, 1);
  }

  int get longestStreak {
    if (_habits.isEmpty) return 0;
    return _habits.fold<int>(0, (max, h) => h.streak > max ? h.streak : max);
  }

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _habits
        ..clear()
        ..addAll(decoded
            .map((e) => Habit.fromJson(e as Map<String, dynamic>))
            .toList());
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    int targetPerWeek = 7,
    int? colorValue,
  }) async {
    final color =
        colorValue ?? palette[_habits.length % palette.length];
    _habits.add(
      Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        targetPerWeek: targetPerWeek.clamp(1, 7),
        completions: {},
        colorValue: color,
        createdAt: DateTime.now(),
      ),
    );
    await _save();
  }

  Future<void> toggleCompletionForToday(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final key = _dateKey(DateTime.now());
    final completions = {...habit.completions};
    if (completions.contains(key)) {
      completions.remove(key);
    } else {
      completions.add(key);
    }
    _habits[index] = habit.copyWith(completions: completions);
    await _save();
  }

  Future<void> updateHabit(
    String id, {
    String? name,
    int? targetPerWeek,
    int? colorValue,
  }) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    _habits[index] = habit.copyWith(
      name: name,
      targetPerWeek: targetPerWeek != null
          ? targetPerWeek.clamp(1, 7)
          : null,
      colorValue: colorValue,
    );
    await _save();
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    await _save();
  }

  Future<void> resetCompletions(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = _habits[index];
    _habits[index] = habit.copyWith(completions: <String>{});
    await _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
    notifyListeners();
  }
}

String _dateKey(DateTime date) {
  final d = _normalize(date);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

DateTime _parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return _normalize(DateTime.now());
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isBeforeDay(DateTime a, DateTime b) => _normalize(a).isBefore(_normalize(b));

bool _isAfterDay(DateTime a, DateTime b) => _normalize(a).isAfter(_normalize(b));
