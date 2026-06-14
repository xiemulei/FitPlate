import '../models/food.dart';

/// 计算每种食物在目标下的最终克数（按蛋白质目标缩放）
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

    final totalWeightedProtein =
        selFoods.fold(0.0, (sum, f) => sum + f.$1.proteinPer100G / 100 * f.$2);
    if (totalWeightedProtein <= 0) return {};

    final k = target.protein / totalWeightedProtein;
    return {for (final f in selFoods) f.$1: f.$2 * k};
  }

  /// 计算实际的蛋白质和碳水量
  static ({double protein, double carbs}) calculateActual(
      Map<Food, double> results) {
    final protein = results.entries.fold(
        0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
    final carbs = results.entries.fold(
        0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);
    return (protein: protein, carbs: carbs);
  }
}

/// 将克数转换为食物对应的显示单位
class FoodAmountFormatter {
  static String formatAmount(Food food, double grams) {
    if (food.unit.isItemUnit &&
        food.gramsPerUnit != null &&
        food.gramsPerUnit! > 0) {
      final count = grams / food.gramsPerUnit!;
      return '${count.toStringAsFixed(1)}${food.unit.label}';
    }
    return '${grams.toStringAsFixed(0)}g';
  }
}
