import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/food.dart';
import '../models/user_profile.dart';
import '../models/cycle.dart';

class StorageService {
  static Future<Directory> get _dir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'macro_meal_data'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> _path(String name) async {
    final d = await _dir;
    return p.join(d.path, name);
  }

  // Save/Load templates
  static Future<List<MealTemplate>> loadTemplates() async {
    try {
      final f = await _path('templates.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => MealTemplate.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveTemplates(List<MealTemplate> templates) async {
    final f = await _path('templates.json');
    await File(f).writeAsString(jsonEncode(templates.map((t) => t.toJson()).toList()));
  }

  // Save/Load plans
  static Future<List<WeeklyPlan>> loadPlans() async {
    try {
      final f = await _path('plans.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => WeeklyPlan.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  static Future<void> savePlans(List<WeeklyPlan> plans) async {
    final f = await _path('plans.json');
    await File(f).writeAsString(jsonEncode(plans.map((p) => p.toJson()).toList()));
  }


  // Save/Load profile
  static Future<UserProfile> loadProfile() async {
    try {
      final f = await _path('profile.json');
      if (!await File(f).exists()) return UserProfile();
      final s = await File(f).readAsString();
      return UserProfile.fromJson(jsonDecode(s));
    } catch (_) { return UserProfile(); }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final f = await _path('profile.json');
    await File(f).writeAsString(jsonEncode(profile.toJson()));
  }


  // Save/Load cycles
  static Future<List<TrainingCycle>> loadCycles() async {
    try {
      final f = await _path('cycles.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => TrainingCycle.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveCycles(List<TrainingCycle> cycles) async {
    final f = await _path('cycles.json');
    await File(f).writeAsString(jsonEncode(cycles.map((c) => c.toJson()).toList()));
  }
}