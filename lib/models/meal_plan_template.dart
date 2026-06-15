import 'user_profile.dart';
import '../data/meal_distribution.dart';

/// 配餐方案中的一餐定义
class MealSlotDef {
  String name;       // 餐名，如"练后餐"
  double carbRatio;  // 占每日总量的比例 0~1
  double proteinRatio;
  List<FoodAssignment> foods; // 已选食物

  MealSlotDef({
    required this.name,
    required this.carbRatio,
    required this.proteinRatio,
    List<FoodAssignment>? foods,
  }) : foods = foods ?? [];

  MealSlotDef copyWith({
    String? name,
    double? carbRatio,
    double? proteinRatio,
    List<FoodAssignment>? foods,
  }) =>
      MealSlotDef(
        name: name ?? this.name,
        carbRatio: carbRatio ?? this.carbRatio,
        proteinRatio: proteinRatio ?? this.proteinRatio,
        foods: foods ?? List.from(this.foods),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'carbRatio': carbRatio,
        'proteinRatio': proteinRatio,
        'foods': foods.map((f) => f.toJson()).toList(),
      };

  factory MealSlotDef.fromJson(Map<String, dynamic> j) => MealSlotDef(
        name: j['name'],
        carbRatio: (j['carbRatio'] as num).toDouble(),
        proteinRatio: (j['proteinRatio'] as num).toDouble(),
        foods: (j['foods'] as List?)
                ?.map((e) => FoodAssignment.fromJson(e))
                .toList() ??
            [],
      );
}

/// 某餐已选的食物 + 克数
class FoodAssignment {
  String foodId;
  double grams;

  FoodAssignment({required this.foodId, required this.grams});

  Map<String, dynamic> toJson() => {'foodId': foodId, 'grams': grams};

  factory FoodAssignment.fromJson(Map<String, dynamic> j) => FoodAssignment(
        foodId: j['foodId'],
        grams: (j['grams'] as num).toDouble(),
      );
}

/// 完整配餐方案（有一天完整的各餐配比 + 可选食物选择）
class MealPlanTemplate {
  final String id;
  String name;
  final bool isBuiltIn;
  final TrainingTime? sourceTime; // 内置方案对应的训练时段
  List<MealSlotDef> trainingMeals; // 训练日各餐
  List<MealSlotDef> restMeals;     // 休息日各餐

  MealPlanTemplate({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
    this.sourceTime,
    List<MealSlotDef>? trainingMeals,
    List<MealSlotDef>? restMeals,
  })  : trainingMeals = trainingMeals ?? [],
        restMeals = restMeals ?? [];

  /// 从内置 MealDistribution 创建预设模板
  factory MealPlanTemplate.fromDistribution(MealDistribution dist) {
    return MealPlanTemplate(
      id: 'builtin_${dist.trainingTime.name}',
      name: dist.trainingTime.label,
      isBuiltIn: true,
      sourceTime: dist.trainingTime,
      trainingMeals: dist.trainingDayMeals
          .map((m) => MealSlotDef(
                name: m.name,
                carbRatio: m.carbRatio,
                proteinRatio: m.proteinRatio,
              ))
          .toList(),
      restMeals: dist.restDayMeals
          .map((m) => MealSlotDef(
                name: m.name,
                carbRatio: m.carbRatio,
                proteinRatio: m.proteinRatio,
              ))
          .toList(),
    );
  }

  /// 所有内置预设模板
  static List<MealPlanTemplate> builtIns() =>
      MealDistributions.all.map((d) => MealPlanTemplate.fromDistribution(d)).toList();

  MealPlanTemplate copyWith({
    String? id,
    String? name,
    bool? isBuiltIn,
    TrainingTime? sourceTime,
    List<MealSlotDef>? trainingMeals,
    List<MealSlotDef>? restMeals,
  }) =>
      MealPlanTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        sourceTime: sourceTime ?? this.sourceTime,
        trainingMeals: trainingMeals ?? List.from(this.trainingMeals),
        restMeals: restMeals ?? List.from(this.restMeals),
      );

  /// 根据个人资料计算各餐实际克数（训练日）
  List<({String name, double carbG, double proteinG})> calcTrainingDay(
      UserProfile profile) {
    final dc = profile.dailyCarbs;
    final dp = profile.dailyProtein;
    return trainingMeals.map((m) => (
      name: m.name,
      carbG: dc * m.carbRatio,
      proteinG: dp * m.proteinRatio,
    )).toList();
  }

  /// 根据个人资料计算各餐实际克数（休息日）
  List<({String name, double carbG, double proteinG})> calcRestDay(
      UserProfile profile) {
    final dc = profile.dailyCarbs;
    final dp = profile.dailyProtein;
    return restMeals.map((m) => (
      name: m.name,
      carbG: dc * m.carbRatio,
      proteinG: dp * m.proteinRatio,
    )).toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBuiltIn': isBuiltIn,
        'sourceTime': sourceTime?.name,
        'trainingMeals': trainingMeals.map((m) => m.toJson()).toList(),
        'restMeals': restMeals.map((m) => m.toJson()).toList(),
      };

  factory MealPlanTemplate.fromJson(Map<String, dynamic> j) =>
      MealPlanTemplate(
        id: j['id'],
        name: j['name'],
        isBuiltIn: j['isBuiltIn'] ?? false,
        sourceTime: j['sourceTime'] != null
            ? TrainingTime.values.firstWhere(
                (t) => t.name == j['sourceTime'],
                orElse: () => TrainingTime.afterLunch)
            : null,
        trainingMeals: (j['trainingMeals'] as List)
            .map((e) => MealSlotDef.fromJson(e))
            .toList(),
        restMeals: (j['restMeals'] as List)
            .map((e) => MealSlotDef.fromJson(e))
            .toList(),
      );
}
