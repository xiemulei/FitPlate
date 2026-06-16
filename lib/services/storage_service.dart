import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/food.dart';
import '../models/user_profile.dart';
import '../models/cycle.dart';
import '../models/meal_plan_template.dart';

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
    } catch (e) {
      debugPrint('StorageService.loadTemplates: $e');
      return [];
    }
  }

  static Future<void> saveTemplates(List<MealTemplate> templates) async {
    final f = await _path('templates.json');
    await File(f)
        .writeAsString(jsonEncode(templates.map((t) => t.toJson()).toList()));
  }

  // Save/Load plans
  static Future<List<WeeklyPlan>> loadPlans() async {
    try {
      final f = await _path('plans.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => WeeklyPlan.fromJson(j)).toList();
    } catch (e) {
      debugPrint('StorageService.loadPlans: $e');
      return [];
    }
  }

  static Future<void> savePlans(List<WeeklyPlan> plans) async {
    final f = await _path('plans.json');
    await File(f)
        .writeAsString(jsonEncode(plans.map((p) => p.toJson()).toList()));
  }

  // Save/Load profile
  static Future<UserProfile> loadProfile() async {
    try {
      final f = await _path('profile.json');
      if (!await File(f).exists()) return UserProfile();
      final s = await File(f).readAsString();
      return UserProfile.fromJson(jsonDecode(s));
    } catch (e) {
      debugPrint('StorageService.loadProfile: $e');
      return UserProfile();
    }
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
      final cycles = list.map((j) => TrainingCycle.fromJson(j)).toList();
      if (cycles.where((c) => c.isActive).length > 1) {
        debugPrint('StorageService.loadCycles: 检测到多个活跃循环，仅保留第一个');
        var seenFirst = false;
        return cycles.map((c) {
          if (c.isActive && !seenFirst) {
            seenFirst = true;
            return c;
          }
          return c.copyWith(isActive: false);
        }).toList();
      }
      return cycles;
    } catch (e) {
      debugPrint('StorageService.loadCycles: $e');
      return [];
    }
  }

  static Future<void> saveCycles(List<TrainingCycle> cycles) async {
    final f = await _path('cycles.json');
    await File(f).writeAsString(jsonEncode(cycles.map((c) => c.toJson()).toList()));
  }

  // ═════════════════════════════════
  //  配餐方案模板
  // ═════════════════════════════════

  static Future<List<MealPlanTemplate>> loadMealPlanTemplates() async {
    try {
      final f = await _path('meal_plans.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => MealPlanTemplate.fromJson(j)).toList();
    } catch (e) {
      debugPrint('StorageService.loadMealPlanTemplates: $e');
      return [];
    }
  }

  static Future<void> saveMealPlanTemplates(
      List<MealPlanTemplate> templates) async {
    final f = await _path('meal_plans.json');
    await File(f).writeAsString(
        jsonEncode(templates.where((t) => !t.isBuiltIn).map((t) => t.toJson()).toList()));
  }

  // Save/Load custom foods
  static Future<List<Food>> loadFoods() async {
    try {
      final f = await _path('foods.json');
      if (!await File(f).exists()) return [];
      final s = await File(f).readAsString();
      final list = jsonDecode(s) as List;
      return list.map((j) => Food.fromJson(j)).toList();
    } catch (e) {
      debugPrint('StorageService.loadFoods: $e');
      return [];
    }
  }

  static Future<void> saveFoods(List<Food> foods) async {
    final f = await _path('foods.json');
    await File(f).writeAsString(jsonEncode(foods.map((f) => f.toJson()).toList()));
  }
}
