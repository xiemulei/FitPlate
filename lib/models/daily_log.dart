/// 某餐的已选食物记录（持久化用）
class FoodServingRecord {
  String foodId;
  String foodName;
  double grams;
  double carbsPer100G;
  double proteinPer100G;

  FoodServingRecord({
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.carbsPer100G,
    required this.proteinPer100G,
  });

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'foodName': foodName,
        'grams': grams,
        'carbsPer100G': carbsPer100G,
        'proteinPer100G': proteinPer100G,
      };

  factory FoodServingRecord.fromJson(Map<String, dynamic> j) =>
      FoodServingRecord(
        foodId: j['foodId'] as String,
        foodName: j['foodName'] as String,
        grams: (j['grams'] as num).toDouble(),
        carbsPer100G: (j['carbsPer100G'] as num).toDouble(),
        proteinPer100G: (j['proteinPer100G'] as num).toDouble(),
      );
}

/// 一餐的食物记录
class MealFoodLog {
  int mealIndex;
  String mealLabel;
  int targetCarbsG;
  int targetProteinG;
  List<FoodServingRecord> servings;

  MealFoodLog({
    required this.mealIndex,
    required this.mealLabel,
    required this.targetCarbsG,
    required this.targetProteinG,
    this.servings = const [],
  });

  Map<String, dynamic> toJson() => {
        'mealIndex': mealIndex,
        'mealLabel': mealLabel,
        'targetCarbsG': targetCarbsG,
        'targetProteinG': targetProteinG,
        'servings': servings.map((s) => s.toJson()).toList(),
      };

  factory MealFoodLog.fromJson(Map<String, dynamic> j) => MealFoodLog(
        mealIndex: j['mealIndex'] as int,
        mealLabel: j['mealLabel'] as String,
        targetCarbsG: j['targetCarbsG'] as int,
        targetProteinG: j['targetProteinG'] as int,
        servings: (j['servings'] as List)
            .map((s) => FoodServingRecord.fromJson(s))
            .toList(),
      );
}

/// 某天的完整饮食记录
class DailyFoodLog {
  String date; // "2026-06-17"
  int cycleDayIndex; // 0-based
  bool isRestDay;
  String cycleName;
  List<MealFoodLog> meals;

  DailyFoodLog({
    required this.date,
    required this.cycleDayIndex,
    required this.isRestDay,
    required this.cycleName,
    this.meals = const [],
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'cycleDayIndex': cycleDayIndex,
        'isRestDay': isRestDay,
        'cycleName': cycleName,
        'meals': meals.map((m) => m.toJson()).toList(),
      };

  factory DailyFoodLog.fromJson(Map<String, dynamic> j) => DailyFoodLog(
        date: j['date'] as String,
        cycleDayIndex: j['cycleDayIndex'] as int,
        isRestDay: j['isRestDay'] as bool,
        cycleName: j['cycleName'] as String? ?? '',
        meals: (j['meals'] as List)
            .map((m) => MealFoodLog.fromJson(m))
            .toList(),
      );

  /// 今天的日期字符串
  static String todayDate() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
