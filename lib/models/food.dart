class Food {
  final String id;
  final String name;
  final String unit;
  final double proteinPer100G;
  final double carbsPer100G;

  Food({
    required this.id,
    required this.name,
    this.unit = 'g/100g',
    required this.proteinPer100G,
    required this.carbsPer100G,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'unit': unit,
    'proteinPer100G': proteinPer100G, 'carbsPer100G': carbsPer100G,
  };

  factory Food.fromJson(Map<String, dynamic> j) => Food(
    id: j['id'], name: j['name'],
    unit: j['unit'] ?? 'g/100g',
    proteinPer100G: (j['proteinPer100G'] as num).toDouble(),
    carbsPer100G: (j['carbsPer100G'] as num).toDouble(),
  );
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

  MealTemplate({required this.id, required this.name, required this.target, required this.selections});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'target': target.toJson(),
    'selections': selections.map((s) => s.toJson()).toList(),
  };

  factory MealTemplate.fromJson(Map<String, dynamic> j) => MealTemplate(
    id: j['id'], name: j['name'],
    target: MealTarget.fromJson(j['target']),
    selections: (j['selections'] as List).map((s) => SelectedFood.fromJson(s)).toList(),
  );
}

class MealType {
  final String name;
  double defaultProtein;
  double defaultCarbs;

  MealType({required this.name, required this.defaultProtein, required this.defaultCarbs});

  static final List<MealType> defaults = [
    MealType(name: '早餐', defaultProtein: 20, defaultCarbs: 30),
    MealType(name: '午餐', defaultProtein: 35, defaultCarbs: 40),
    MealType(name: '晚餐', defaultProtein: 30, defaultCarbs: 25),
    MealType(name: '练后餐', defaultProtein: 35, defaultCarbs: 40),
    MealType(name: '加餐', defaultProtein: 15, defaultCarbs: 20),
  ];
}

class MealCalculator {
  static Map<Food, double> calculate({
    required MealTarget target,
    required List<Food> allFoods,
    required List<SelectedFood> selected,
  }) {
    final selFoods = selected.map((sf) {
      final food = allFoods.firstWhere((f) => f.id == sf.foodId);
      return (food, sf.ratio);
    }).toList();

    final totalWeightedProtein = selFoods.fold(0.0, (sum, f) => sum + f.$1.proteinPer100G / 100 * f.$2);
    if (totalWeightedProtein <= 0) return {};

    final k = target.protein / totalWeightedProtein;
    return {for (final f in selFoods) f.$1: f.$2 * k};
  }
}

class PlanSlot {
  final int day;
  final int meal;
  final String templateId;
  PlanSlot({required this.day, required this.meal, required this.templateId});

  Map<String, dynamic> toJson() => {'day': day, 'meal': meal, 'templateId': templateId};
  factory PlanSlot.fromJson(Map<String, dynamic> j) => PlanSlot(
    day: j['day'], meal: j['meal'], templateId: j['templateId'],
  );
}

class WeeklyPlan {
  final String id;
  final String name;
  final List<PlanSlot> slots;
  WeeklyPlan({required this.id, required this.name, this.slots = const []});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory WeeklyPlan.fromJson(Map<String, dynamic> j) => WeeklyPlan(
    id: j['id'], name: j['name'],
    slots: (j['slots'] as List).map((s) => PlanSlot.fromJson(s)).toList(),
  );
}
