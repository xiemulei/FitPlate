import '../models/food.dart';

/// 一餐的营养目标
class MealPlanEntry {
  final MealType? type;
  final String label;
  final int proteinG;
  final int carbsG;

  const MealPlanEntry({
    this.type,
    required this.label,
    required this.proteinG,
    required this.carbsG,
  });
}
