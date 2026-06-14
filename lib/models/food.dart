/// 食物单位枚举
enum FoodUnit {
  grams100g('g/100g'), // 默认
  grams100ml('g/100ml'), // 液体
  piece('个'), // 个
  serving('份'), // 份
  cup('杯'); // 杯

  final String label;
  const FoodUnit(this.label);

  bool get isItemUnit =>
      this == FoodUnit.piece ||
      this == FoodUnit.serving ||
      this == FoodUnit.cup;
  bool get isStandardUnit =>
      this == FoodUnit.grams100g || this == FoodUnit.grams100ml;

  static FoodUnit fromString(String s) {
    for (final u in FoodUnit.values) {
      if (u.label == s) return u;
    }
    return FoodUnit.grams100g;
  }
}

class Food {
  final String id;
  final String name;
  final FoodUnit unit;
  final double proteinPer100G;
  final double carbsPer100G;
  final String category; // '主食', '蛋白质-纯瘦肉', '蛋白质-蛋白粉', '未分类'
  final String? subcategory; // 主食子类: '米饭粥类', '面食类', '杂粮类', '面包类', '根茎类'
  /// 对于"个/份/杯"等按件计量的单位，每件相当于多少克
  /// 例如：1个鸡蛋=50g，1份米饭=200g，1杯牛奶=250ml
  final double? gramsPerUnit;

  Food({
    required this.id,
    required this.name,
    this.unit = FoodUnit.grams100g,
    required this.proteinPer100G,
    required this.carbsPer100G,
    this.category = '未分类',
    this.subcategory,
    this.gramsPerUnit,
  });

  /// 显示单位文本（如 "g/100g", "个"）
  String get unitLabel => unit.label;

  /// 营养数据的基准单位文本（用于详情显示）
  String get baseUnitLabel {
    if (unit == FoodUnit.piece) return 'g/个';
    if (unit == FoodUnit.serving) return 'g/份';
    if (unit == FoodUnit.cup) return 'g/杯';
    return 'g/100g';
  }

  /// 如果是指定数量的单位，每单位相当于多少克
  double get effectiveGramsPerUnit {
    if (gramsPerUnit != null && gramsPerUnit! > 0) return gramsPerUnit!;
    return 100.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit.label,
        'proteinPer100G': proteinPer100G,
        'carbsPer100G': carbsPer100G,
        'category': category,
        'subcategory': subcategory,
        if (gramsPerUnit != null) 'gramsPerUnit': gramsPerUnit,
      };

  factory Food.fromJson(Map<String, dynamic> j) => Food(
        id: j['id'],
        name: j['name'],
        unit: j['unit'] != null
            ? FoodUnit.fromString(j['unit'])
            : FoodUnit.grams100g,
        proteinPer100G: (j['proteinPer100G'] as num).toDouble(),
        carbsPer100G: (j['carbsPer100G'] as num).toDouble(),
        category: j['category'] ?? '未分类',
        subcategory: j['subcategory'],
        gramsPerUnit: (j['gramsPerUnit'] as num?)?.toDouble(),
      );

  /// 分类标签（含子类），用于显示
  String get categoryLabel {
    if (subcategory != null && subcategory!.isNotEmpty) {
      return '$category · $subcategory';
    }
    return category;
  }
}

class MealTarget {
  double protein;
  double carbs;
  MealTarget({required this.protein, required this.carbs});

  Map<String, dynamic> toJson() => {'protein': protein, 'carbs': carbs};
  factory MealTarget.fromJson(Map<String, dynamic> j) => MealTarget(
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
      );
}

class SelectedFood {
  final String foodId;
  final double ratio;
  SelectedFood({required this.foodId, required this.ratio});

  Map<String, dynamic> toJson() => {'foodId': foodId, 'ratio': ratio};
  factory SelectedFood.fromJson(Map<String, dynamic> j) => SelectedFood(
        foodId: j['foodId'],
        ratio: (j['ratio'] as num).toDouble(),
      );
}

class MealTemplate {
  final String id;
  final String name;
  final MealTarget target;
  final List<SelectedFood> selections;

  MealTemplate(
      {required this.id,
      required this.name,
      required this.target,
      required this.selections});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target.toJson(),
        'selections': selections.map((s) => s.toJson()).toList(),
      };

  factory MealTemplate.fromJson(Map<String, dynamic> j) => MealTemplate(
        id: j['id'],
        name: j['name'],
        target: MealTarget.fromJson(j['target']),
        selections: (j['selections'] as List)
            .map((s) => SelectedFood.fromJson(s))
            .toList(),
      );
}

class MealType {
  final String name;
  double defaultProtein;
  double defaultCarbs;

  MealType(
      {required this.name,
      required this.defaultProtein,
      required this.defaultCarbs});

  static final List<MealType> defaults = [
    MealType(name: '早餐', defaultProtein: 20, defaultCarbs: 30),
    MealType(name: '午餐', defaultProtein: 35, defaultCarbs: 40),
    MealType(name: '晚餐', defaultProtein: 30, defaultCarbs: 25),
    MealType(name: '练后餐', defaultProtein: 35, defaultCarbs: 40),
    MealType(name: '加餐', defaultProtein: 15, defaultCarbs: 20),
  ];
}

// MealCalculator 和 FoodAmountFormatter 已移至 lib/utils/meal_utils.dart
class PlanSlot {
  final int day;
  final int meal;
  final String templateId;
  PlanSlot({required this.day, required this.meal, required this.templateId});

  Map<String, dynamic> toJson() =>
      {'day': day, 'meal': meal, 'templateId': templateId};
  factory PlanSlot.fromJson(Map<String, dynamic> j) => PlanSlot(
        day: j['day'],
        meal: j['meal'],
        templateId: j['templateId'],
      );
}

class WeeklyPlan {
  final String id;
  final String name;
  final List<PlanSlot> slots;
  WeeklyPlan({required this.id, required this.name, this.slots = const []});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory WeeklyPlan.fromJson(Map<String, dynamic> j) => WeeklyPlan(
        id: j['id'],
        name: j['name'],
        slots: (j['slots'] as List).map((s) => PlanSlot.fromJson(s)).toList(),
      );
}
