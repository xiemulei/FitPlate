import '../models/user_profile.dart';
import '../models/food.dart';

/// 一餐在每日总摄入中的比例
class MealPortion {
  final String name;
  final double carbRatio;    // 0~1，占每日总碳水的比例
  final double proteinRatio; // 0~1，占每日总蛋白的比例

  const MealPortion(this.name, this.carbRatio, this.proteinRatio);
}

/// 某训练时间下的完整配餐比例方案
class MealDistribution {
  final TrainingTime trainingTime;
  final List<MealPortion> trainingDayMeals;
  final List<MealPortion> restDayMeals;

  const MealDistribution({
    required this.trainingTime,
    required this.trainingDayMeals,
    required this.restDayMeals,
  });

  /// 根据餐次名称关键词查找对应的配餐比例
  MealPortion? findPortion(MealType type, {bool isTrainingDay = true}) {
    final meals = isTrainingDay ? trainingDayMeals : restDayMeals;
    final keyword = _keywordForType(type);
    for (final m in meals) {
      if (m.name.contains(keyword)) return m;
    }
    return null;
  }

  /// 根据配餐比例计算该餐的营养目标（克数）
  MealTarget calculateTarget(
    MealType type,
    UserProfile profile, {
    bool isTrainingDay = true,
  }) {
    final portion = findPortion(type, isTrainingDay: isTrainingDay);
    if (portion == null) {
      // 找不到匹配，返回最简单的均分
      final meals = isTrainingDay ? trainingDayMeals : restDayMeals;
      final count = meals.length;
      return MealTarget(
        protein: profile.dailyProtein / count,
        carbs: profile.dailyCarbs / count,
      );
    }
    return MealTarget(
      protein: profile.dailyProtein * portion.proteinRatio,
      carbs: profile.dailyCarbs * portion.carbRatio,
    );
  }

  static String _keywordForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return '早';
      case MealType.lunch:
        return '午';
      case MealType.dinner:
        return '晚';
      case MealType.postWorkout:
        return '练后';
      case MealType.snack:
        return '零食';
    }
  }
}

/// 所有训练时间的配餐比例定义
///
/// 数据来源：B站好人松松《健身Excel超级套表》
/// 每个比例代表该餐占 **每日总量** 的百分比
class MealDistributions {
  static const all = [
    // ═══ 1. 早饭后练（早起版） ═══
    // 训练日：①早饭=练前餐(垫) → ②练后餐(最大) → ③午饭 → ④晚饭 → ⑤零食
    // 休息日：①早饭 → ②午饭 → ③晚饭 → ④零食
    MealDistribution(
      trainingTime: TrainingTime.afterEarlyBreakfast,
      trainingDayMeals: [
        MealPortion('①早饭=练前餐', 0.15, 0.20),
        MealPortion('②练后餐', 0.35, 0.20),
        MealPortion('③午饭', 0.20, 0.20),
        MealPortion('④晚饭', 0.20, 0.20),
        MealPortion('⑤零食/夜宵', 0.10, 0.20),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),

    // ═══ 2. 早饭后练（晚起版） ═══
    // 起床晚 → 练后餐是午饭
    MealDistribution(
      trainingTime: TrainingTime.afterLateBreakfast,
      trainingDayMeals: [
        MealPortion('①早饭=练前餐', 0.15, 0.20),
        MealPortion('②午饭=练后餐', 0.35, 0.20),
        MealPortion('③晚饭', 0.30, 0.30),
        MealPortion('④零食/夜宵', 0.20, 0.30),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),

    // ═══ 3. 午饭前练 ═══
    // 练前餐垫肚子 → 午饭=练后餐(最大)
    MealDistribution(
      trainingTime: TrainingTime.beforeLunch,
      trainingDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②练前餐', 0.15, 0.00),
        MealPortion('③午饭=练后餐', 0.35, 0.30),
        MealPortion('④晚饭', 0.20, 0.30),
        MealPortion('⑤零食/夜宵', 0.10, 0.20),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),

    // ═══ 4. 午饭后练 ═══
    // 午饭=练前餐(垫) → 练后餐(最大) → 晚饭
    MealDistribution(
      trainingTime: TrainingTime.afterLunch,
      trainingDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭=练前餐', 0.15, 0.00),
        MealPortion('③练后餐', 0.35, 0.30),
        MealPortion('④晚饭', 0.20, 0.30),
        MealPortion('⑤零食/夜宵', 0.10, 0.20),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),

    // ═══ 5. 晚饭后练 ═══
    // 晚饭=练前餐(垫) → 练后餐(最大)
    MealDistribution(
      trainingTime: TrainingTime.afterDinner,
      trainingDayMeals: [
        MealPortion('①早饭', 0.20, 0.25),
        MealPortion('②午饭', 0.20, 0.25),
        MealPortion('③晚饭=练前餐', 0.15, 0.00),
        MealPortion('④练后餐', 0.35, 0.30),
        MealPortion('⑤零食/夜宵', 0.10, 0.20),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),

    // ═══ 6. 夜里练 ═══
    // 晚饭 → 练前餐(垫) → 练后餐
    MealDistribution(
      trainingTime: TrainingTime.night,
      trainingDayMeals: [
        MealPortion('①早饭', 0.20, 0.25),
        MealPortion('②午饭', 0.20, 0.25),
        MealPortion('③晚饭', 0.20, 0.25),
        MealPortion('④练前餐', 0.15, 0.00),
        MealPortion('⑤练后餐', 0.25, 0.25),
      ],
      restDayMeals: [
        MealPortion('①早饭', 0.20, 0.20),
        MealPortion('②午饭', 0.35, 0.30),
        MealPortion('③晚饭', 0.35, 0.30),
        MealPortion('④零食/夜宵', 0.10, 0.20),
      ],
    ),
  ];

  /// 查找某训练时间的配餐方案
  static MealDistribution? forTrainingTime(TrainingTime time) {
    for (final d in all) {
      if (d.trainingTime == time) return d;
    }
    return null;
  }

  /// 无力量训练者的配餐（每天都一样，不分训练/休息日）
  static const noStrengthMeals = [
    MealPortion('①早饭', 0.20, 0.20),
    MealPortion('②午饭', 0.35, 0.30),
    MealPortion('③晚饭', 0.35, 0.30),
    MealPortion('④零食/夜宵', 0.10, 0.20),
  ];

  /// 根据餐次名称在无力训表中查找配餐比例
  static MealPortion? findNoStrengthPortion(MealType type) {
    final keyword = MealDistribution._keywordForType(type);
    for (final m in noStrengthMeals) {
      if (m.name.contains(keyword)) return m;
    }
    return null;
  }
}
