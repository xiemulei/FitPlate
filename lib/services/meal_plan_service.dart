import '../models/user_profile.dart';
import '../models/cycle.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_template.dart';
import '../data/meal_distribution.dart';

/// 根据训练循环 + 个人资料动态生成每日配餐目标
///
/// 每次调用实时计算，不持久化存储。
/// 个人资料变更后，计算结果自动更新。
class MealPlanService {
  /// 获取活跃循环今日的每餐目标
  /// 返回 null 表示无活跃循环或循环已过期
  static List<MealPlanEntry>? getTodayMeals({
    required TrainingCycle activeCycle,
    required UserProfile profile,
    MealPlanTemplate? customTemplate,
  }) {
    final todayDay = activeCycle.todayDay;
    if (todayDay == null) return null;

    // 如果有自定义方案，优先使用
    if (customTemplate != null) {
      return _entriesFromTemplate(customTemplate, todayDay.isRestDay, profile);
    }

    return generateDayMeals(
      isRestDay: todayDay.isRestDay,
      profile: profile,
      trainingTime: activeCycle.trainingTime ?? profile.trainingTime,
    );
  }

  /// 为一个完整的循环生成全部日期的配餐
  static List<List<MealPlanEntry>> generateCycleMeals({
    required TrainingCycle cycle,
    required UserProfile profile,
    MealPlanTemplate? customTemplate,
  }) {
    return cycle.days.map((day) {
      // 如果有自定义方案，优先使用
      if (customTemplate != null) {
        return _entriesFromTemplate(customTemplate, day.isRestDay, profile);
      }

      return generateDayMeals(
        isRestDay: day.isRestDay,
        profile: profile,
        trainingTime: cycle.trainingTime ?? profile.trainingTime,
      );
    }).toList();
  }

  /// 单日生成（预设方案）
  static List<MealPlanEntry> generateDayMeals({
    required bool isRestDay,
    required UserProfile profile,
    required TrainingTime trainingTime,
  }) {
    final isStrengthTraining = !profile.noStrengthTraining;
    final entries = <MealPlanEntry>[];

    if (isStrengthTraining && !isRestDay) {
      // ── 训练日（有力量训练）─ 用训练日配餐 ──
      final dist = MealDistributions.forTrainingTime(trainingTime);
      if (dist != null) {
        for (final portion in dist.trainingDayMeals) {
          entries.add(_toEntry(portion, profile));
        }
        return entries;
      }
    }

    // ── 休息日 / 无力训 ──
    final allMeals = isStrengthTraining
        ? MealDistributions.forTrainingTime(trainingTime)?.restDayMeals
        : MealDistributions.noStrengthMeals;

    for (final portion in allMeals ?? MealDistributions.noStrengthMeals) {
      entries.add(_toEntry(portion, profile, isRestDay: isRestDay));
    }
    return entries;
  }

  /// 从自定义模板生成单日配餐
  /// isRestDay 为 true 用 restMeals，false 用 trainingMeals
  static List<MealPlanEntry> _entriesFromTemplate(
      MealPlanTemplate template, bool isRestDay, UserProfile profile) {
    final slots = isRestDay ? template.restMeals : template.trainingMeals;
    final dailyCarbs = isRestDay ? profile.dailyRestCarbs : profile.dailyCarbs;
    return slots.map((slot) => _slotToEntry(slot, profile, dailyCarbs, isRestDay)).toList();
  }

  static MealPlanEntry _toEntry(MealPortion portion, UserProfile profile, {bool isRestDay = false}) {
    final label = portion.name.replaceAll(RegExp(r'[①②③④⑤]'), '').trim();
    final dailyCarbs = isRestDay ? profile.dailyRestCarbs : profile.dailyCarbs;
    return MealPlanEntry(
      type: _matchMealType(portion.name),
      label: label,
      proteinG: (profile.dailyProtein * portion.proteinRatio).round(),
      carbsG: (dailyCarbs * portion.carbRatio).round(),
    );
  }

  /// 将 MealSlotDef 转换为 MealPlanEntry
  static MealPlanEntry _slotToEntry(
      MealSlotDef slot, UserProfile profile, double dailyCarbs, bool isRestDay) {
    final label = slot.name.replaceAll(RegExp(r'[①②③④⑤]'), '').trim();
    return MealPlanEntry(
      type: _matchMealType(slot.name),
      label: label,
      proteinG: (profile.dailyProtein * slot.proteinRatio).round(),
      carbsG: (dailyCarbs * slot.carbRatio).round(),
    );
  }

  static MealType? _matchMealType(String name) {
    if (name.contains('早')) return MealType.breakfast;
    if (name.contains('练后')) return MealType.postWorkout;
    if (name.contains('午')) return MealType.lunch;
    if (name.contains('晚')) return MealType.dinner;
    if (name.contains('零食') || name.contains('夜宵')) return MealType.snack;
    return null;
  }
}
