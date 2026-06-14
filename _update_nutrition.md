# Update nutrition_reference.dart and profile_screen.dart

## Context

The project at /Users/x/FitPlate is a Flutter app (FitPlate - 健身饮食 App). 

Current `nutrition_reference.dart` only has tables for **no strength training** (无力训男/无力训女) in format `(carbs, protein)`.

Need to add 4 NEW tables for **with strength training** cases, in format `(trainingDayCarbs, restDayCarbs, protein)`, then update the lookup methods and profile screen.

## Files to modify

### 1. /Users/x/FitPlate/lib/data/nutrition_reference.dart

**A) Add 4 new static const maps AFTER the existing `nutritionFemale`:**

`maleFatLoss`: Map<int, Map<int, (double, double, double)?>> — 健身男性减脂
Heights: 160,165,170,175,180,185,190. Weights: 50-130 (5kg steps).

Full data:

160: {
  60: (2.6, 2.0, 1.4), 65: (2.6, 1.9, 1.4), 70: (2.5, 1.9, 1.3),
  75: (2.4, 1.9, 1.3), 80: (2.4, 1.9, 1.3), 85: (2.3, 1.8, 1.2),
  90: (2.3, 1.8, 1.2), 95: (2.2, 1.8, 1.2), 100: (2.2, 1.8, 1.2),
  105: (2.1, 1.8, 1.2), 110: (2.1, 1.8, 1.1), 115: (2.1, 1.7, 1.1),
  120: (1.9, 1.6, 1.0), 125: (1.9, 1.6, 1.0), 130: (1.9, 1.6, 1.0),
}
165: {
  65: (2.6, 2.0, 1.4), 70: (2.5, 2.0, 1.4), 75: (2.5, 1.9, 1.3),
  80: (2.4, 1.9, 1.3), 85: (2.4, 1.9, 1.3), 90: (2.3, 1.9, 1.2),
  95: (2.3, 1.8, 1.2), 100: (2.2, 1.8, 1.2), 105: (2.2, 1.8, 1.2),
  110: (2.2, 1.8, 1.2), 115: (2.1, 1.8, 1.1), 120: (2.1, 1.6, 1.1),
  125: (2.1, 1.6, 1.1), 130: (1.9, 1.6, 1.1),
}
170: {
  70: (2.6, 2.0, 1.4), 75: (2.5, 2.0, 1.4), 80: (2.5, 2.0, 1.3),
  85: (2.4, 1.9, 1.3), 90: (2.4, 1.9, 1.3), 95: (2.3, 1.9, 1.2),
  100: (2.3, 1.9, 1.2), 105: (2.2, 1.9, 1.2), 110: (2.2, 1.8, 1.2),
  115: (2.2, 1.8, 1.2), 120: (2.0, 1.7, 1.1), 125: (2.0, 1.7, 1.1),
  130: (2.0, 1.7, 1.1),
}
175: {
  70: (2.7, 2.1, 1.4), 75: (2.6, 2.1, 1.4), 80: (2.5, 2.0, 1.4),
  85: (2.5, 2.0, 1.3), 90: (2.4, 2.0, 1.3), 95: (2.4, 1.9, 1.3),
  100: (2.3, 1.9, 1.2), 105: (2.3, 1.9, 1.2), 110: (2.2, 1.9, 1.2),
  115: (2.2, 1.9, 1.2), 120: (2.1, 1.7, 1.1), 125: (2.0, 1.7, 1.1),
  130: (2.0, 1.7, 1.1),
}
180: {
  75: (2.7, 2.1, 1.4), 80: (2.6, 2.1, 1.4), 85: (2.5, 2.0, 1.4),
  90: (2.5, 2.0, 1.3), 95: (2.4, 2.0, 1.3), 100: (2.4, 2.0, 1.3),
  105: (2.3, 1.9, 1.2), 110: (2.3, 1.9, 1.2), 115: (2.2, 1.9, 1.2),
  120: (2.1, 1.8, 1.1), 125: (2.1, 1.8, 1.1), 130: (2.0, 1.7, 1.1),
}
185: {
  80: (2.6, 2.1, 1.4), 85: (2.6, 2.1, 1.4), 90: (2.5, 2.1, 1.4),
  95: (2.5, 2.0, 1.3), 100: (2.4, 2.0, 1.3), 105: (2.4, 2.0, 1.3),
  110: (2.3, 2.0, 1.3), 115: (2.3, 1.9, 1.2), 120: (2.1, 1.8, 1.1),
  125: (2.1, 1.8, 1.1), 130: (2.1, 1.8, 1.1),
}
190: {
  85: (2.6, 2.2, 1.4), 90: (2.6, 2.1, 1.4), 95: (2.5, 2.1, 1.3),
  100: (2.5, 2.1, 1.3), 105: (2.4, 2.0, 1.3), 110: (2.4, 2.0, 1.3),
  115: (2.3, 2.0, 1.3), 120: (2.2, 1.8, 1.2), 125: (2.1, 1.8, 1.2),
  130: (2.1, 1.8, 1.1),
}

`maleMuscleGain`: Map<int, Map<int, (double, double, double)?>> — 健身男性增肌
Heights: 160-190. Weights vary.

160: {
  50: (4.0, 3.0, 1.7), 55: (3.8, 2.9, 1.6), 60: (3.7, 2.8, 1.6),
  65: (3.6, 2.8, 1.5), 70: (3.5, 2.7, 1.5),
}
165: {
  50: (4.1, 3.1, 1.8), 55: (4.0, 3.0, 1.7), 60: (3.8, 2.9, 1.6),
  65: (3.7, 2.9, 1.6), 70: (3.6, 2.8, 1.5),
}
170: {
  50: (4.3, 3.2, 1.8), 55: (4.1, 3.1, 1.7), 60: (3.9, 3.0, 1.7),
  65: (3.8, 3.0, 1.6), 70: (3.7, 2.9, 1.6), 75: (3.6, 2.9, 1.5),
}
175: {
  50: (4.4, 3.4, 1.9), 55: (4.2, 3.2, 1.8), 60: (4.0, 3.2, 1.7),
  65: (3.9, 3.1, 1.7), 70: (3.8, 3.0, 1.6), 75: (3.6, 2.9, 1.6),
  80: (3.5, 2.9, 1.5),
}
180: {
  50: (4.5, 3.5, 1.9), 55: (4.3, 3.4, 1.9), 60: (4.1, 3.3, 1.8),
  65: (4.0, 3.2, 1.7), 70: (3.8, 3.1, 1.6), 75: (3.7, 3.0, 1.6),
  80: (3.6, 3.0, 1.6), 85: (3.5, 2.9, 1.5),
}
185: {
  50: (4.7, 3.6, 2.0), 55: (4.4, 3.5, 1.9), 60: (4.2, 3.5, 1.9),
  65: (4.1, 3.3, 1.7), 70: (3.9, 3.2, 1.7), 75: (3.8, 3.1, 1.6),
  80: (3.7, 3.1, 1.6), 85: (3.6, 3.0, 1.5), 90: (3.5, 2.9, 1.5),
}
190: {
  50: (4.8, 3.8, 2.1), 55: (4.6, 3.6, 2.0), 60: (4.4, 3.4, 1.8),
  65: (4.2, 3.4, 1.8), 70: (4.0, 3.3, 1.7), 75: (3.9, 3.2, 1.7),
  80: (3.8, 3.1, 1.6), 85: (3.7, 3.1, 1.6), 90: (3.6, 3.0, 1.5),
}

`femaleFatLoss`: Map<int, Map<int, (double, double, double)?>> — 健身女性减脂
Heights: 150,155,160,165,170,175,180. Weights: 40-120.

150: {
  45: (2.4, 1.8, 1.3), 50: (2.3, 1.8, 1.2), 55: (2.2, 1.8, 1.2),
  60: (2.1, 1.7, 1.2), 65: (2.1, 1.7, 1.1), 70: (2.0, 1.7, 1.1),
  75: (2.0, 1.7, 1.1), 80: (1.9, 1.7, 1.0), 85: (1.9, 1.7, 1.0),
  90: (1.9, 1.7, 1.0), 95: (1.9, 1.6, 1.0), 100: (1.9, 1.6, 1.0),
  105: (1.9, 1.6, 1.0), 110: (1.8, 1.6, 1.0), 115: (1.8, 1.6, 1.0),
  120: (1.8, 1.6, 1.0),
}
155: {
  50: (2.4, 1.9, 1.3), 55: (2.3, 1.9, 1.2), 60: (2.2, 1.8, 1.2),
  65: (2.2, 1.8, 1.2), 70: (2.1, 1.8, 1.1), 75: (2.0, 1.7, 1.1),
  80: (2.0, 1.7, 1.1), 85: (2.0, 1.7, 1.1), 90: (2.0, 1.7, 1.1),
  95: (1.9, 1.7, 1.0), 100: (1.9, 1.7, 1.0), 105: (1.9, 1.7, 1.0),
  110: (1.9, 1.7, 1.0), 115: (1.9, 1.7, 1.0), 120: (1.9, 1.7, 1.0),
}
160: {
  50: (2.5, 2.0, 1.3), 55: (2.4, 1.9, 1.3), 60: (2.3, 1.9, 1.2),
  65: (2.2, 1.9, 1.2), 70: (2.2, 1.8, 1.2), 75: (2.1, 1.8, 1.1),
  80: (2.1, 1.8, 1.1), 85: (2.1, 1.8, 1.1), 90: (2.1, 1.8, 1.1),
  95: (2.1, 1.7, 1.1), 100: (2.1, 1.7, 1.1), 105: (1.9, 1.7, 1.1),
  110: (1.9, 1.7, 1.1), 115: (1.9, 1.7, 1.1), 120: (1.9, 1.7, 1.0),
}
165: {
  55: (2.5, 2.0, 1.3), 60: (2.4, 2.0, 1.3), 65: (2.3, 1.9, 1.2),
  70: (2.2, 1.9, 1.2), 75: (2.2, 1.9, 1.2), 80: (2.2, 1.9, 1.2),
  85: (2.1, 1.8, 1.1), 90: (2.1, 1.8, 1.1), 95: (2.0, 1.8, 1.1),
  100: (2.0, 1.8, 1.1), 105: (2.0, 1.8, 1.1), 110: (2.0, 1.8, 1.1),
  115: (1.9, 1.7, 1.0), 120: (1.9, 1.7, 1.0),
}
170: {
  60: (2.5, 2.1, 1.3), 65: (2.4, 2.0, 1.3), 70: (2.3, 2.0, 1.2),
  75: (2.3, 1.9, 1.2), 80: (2.2, 1.9, 1.2), 85: (2.2, 1.9, 1.2),
  90: (2.1, 1.9, 1.1), 95: (2.1, 1.8, 1.1), 100: (2.1, 1.8, 1.1),
  105: (2.1, 1.8, 1.1), 110: (2.1, 1.8, 1.1), 115: (2.0, 1.8, 1.1),
  120: (2.0, 1.8, 1.1),
}
175: {
  60: (2.5, 2.1, 1.4), 65: (2.5, 2.1, 1.3), 70: (2.4, 2.0, 1.3),
  75: (2.3, 2.0, 1.2), 80: (2.3, 2.0, 1.2), 85: (2.2, 1.9, 1.2),
  90: (2.2, 1.9, 1.2), 95: (2.1, 1.9, 1.2), 100: (2.1, 1.9, 1.2),
  105: (2.1, 1.9, 1.1), 110: (2.1, 1.8, 1.1), 115: (2.0, 1.8, 1.1),
  120: (2.0, 1.8, 1.1),
}
180: {
  65: (2.5, 2.2, 1.4), 70: (2.4, 2.1, 1.3), 75: (2.4, 2.1, 1.3),
  80: (2.3, 2.0, 1.3), 85: (2.3, 2.0, 1.2), 90: (2.2, 2.0, 1.2),
  95: (2.2, 1.9, 1.2), 100: (2.2, 1.9, 1.2), 105: (2.1, 1.9, 1.1),
  110: (2.1, 1.9, 1.1), 115: (2.1, 1.9, 1.1), 120: (2.0, 1.8, 1.1),
}

`femaleMuscleGain`: Map<int, Map<int, (double, double, double)?>> — 健身女性增肌
Heights: 150-180. Weights: 40-80.

150: {
  40: (3.3, 2.5, 1.4), 45: (3.2, 2.5, 1.4), 50: (3.1, 2.4, 1.3),
  55: (3.0, 2.4, 1.3),
}
155: {
  40: (3.5, 2.7, 1.5), 45: (3.3, 2.6, 1.4), 50: (3.2, 2.6, 1.4),
  55: (3.1, 2.5, 1.3),
}
160: {
  40: (3.7, 2.9, 1.6), 45: (3.5, 2.8, 1.5), 50: (3.3, 2.7, 1.4),
  55: (3.2, 2.7, 1.4), 60: (3.1, 2.6, 1.3),
}
165: {
  40: (3.8, 3.0, 1.6), 45: (3.6, 2.9, 1.6), 50: (3.5, 2.8, 1.5),
  55: (3.3, 2.8, 1.4), 60: (3.2, 2.7, 1.4), 65: (3.2, 2.7, 1.4),
}
170: {
  40: (4.0, 3.2, 1.7), 45: (3.8, 3.1, 1.6), 50: (3.6, 3.0, 1.5),
  55: (3.5, 2.9, 1.5), 60: (3.4, 2.8, 1.4), 65: (3.3, 2.8, 1.4),
  70: (3.2, 2.7, 1.4),
}
175: {
  40: (4.1, 3.4, 1.8), 45: (3.9, 3.2, 1.7), 50: (3.7, 3.1, 1.6),
  55: (3.6, 3.0, 1.5), 60: (3.5, 2.9, 1.5), 65: (3.4, 2.9, 1.4),
  70: (3.3, 2.8, 1.4), 75: (3.2, 2.8, 1.4),
}
180: {
  40: (4.3, 3.5, 1.8), 45: (4.1, 3.4, 1.7), 50: (3.9, 3.2, 1.7),
  55: (3.7, 3.1, 1.6), 60: (3.6, 3.0, 1.5), 65: (3.5, 3.0, 1.5),
  70: (3.4, 2.9, 1.4), 75: (3.3, 2.9, 1.4),
}

**B) Add a unified lookup method called `lookupFactor`:**

```dart
  /// 统一查表方法
  /// 返回 (训练日碳水, 休息日碳水, 蛋白质) g/kg，或 null
  /// [isStrengthTraining] 是否做力量训练
  /// [goal] 健身目标
  static (double, double, double)? lookupFactor({
    required bool isMale,
    required int heightCm,
    required int weightKg,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    // 选择对应的表
    final Map<int, Map<int, dynamic>> table;
    if (!isStrengthTraining) {
      table = isMale ? nutritionMale : nutritionFemale;
    } else if (goal == FitnessGoal.fatLoss) {
      table = isMale ? maleFatLoss : femaleFatLoss;
    } else {
      table = isMale ? maleMuscleGain : femaleMuscleGain;
    }

    // 尝试精确匹配身高
    final heightData = table[heightCm];
    if (heightData != null) {
      final val = heightData[weightKg];
      if (val != null) {
        return _normalizeFactor(val);
      }
    }

    // 尝试最近的身高
    final sortedHeights = table.keys.toList()..sort((a, b) {
      return (a - heightCm).abs().compareTo((b - heightCm).abs());
    });
    for (final h in sortedHeights) {
      final weightData = table[h]!;
      final val = weightData[weightKg];
      if (val != null) {
        return _normalizeFactor(val);
      }
      // 在该身高下尝试最近的体重
      final sortedWeights = weightData.keys.toList()..sort((a, b) {
        return (a - weightKg).abs().compareTo((b - weightKg).abs());
      });
      for (final w in sortedWeights) {
        final v = weightData[w];
        if (v != null) {
          return _normalizeFactor(v);
        }
      }
    }

    return null;
  }

  /// 统一转换为 3-tuple：(carb, restCarb, protein)
  static (double, double, double) _normalizeFactor(dynamic val) {
    if (val is (double, double, double)) return val;
    if (val is (double, double)) return (val.$1, val.$1, val.$2);
    throw ArgumentError('Unexpected factor type: ${val.runtimeType}');
  }
```

**C) Update `lookupRecommended` to delegate to `lookupFactor`:**

```dart
  static (double carbsPerKg, double proteinPerKg)? lookupRecommended({
    required bool isMale,
    required int heightCm,
    required int weightKg,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    final result = lookupFactor(
      isMale: isMale,
      heightCm: heightCm,
      weightKg: weightKg,
      isStrengthTraining: isStrengthTraining,
      goal: goal,
    );
    if (result == null) return null;
    // 返回训练日碳水和蛋白质
    return (result.$1, result.$3);
  }
```

**D) Update `recommendationNote` to accept the new params:**

```dart
  static String recommendationNote({
    required bool isMale,
    required int heightCm,
    required int weightKg,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    final result = lookupFactor(
      isMale: isMale,
      heightCm: heightCm,
      weightKg: weightKg,
      isStrengthTraining: isStrengthTraining,
      goal: goal,
    );
    if (result == null) return '当前身高/体重组合暂无参考数据';
    final dailyProtein = result.$3 * weightKg;
    final dailyCarbs = result.$1 * weightKg;
    final genderLabel = isMale ? '男' : '女';
    final scenarioLabel = _scenarioLabel(isStrengthTraining, goal);
    return '基于$scenarioLabel / 身高${heightCm}cm / 体重${weightKg}kg / $genderLabel 推荐：'
        '蛋白质 ${result.$3.toStringAsFixed(1)} g/kg（每日 ${dailyProtein.toStringAsFixed(0)} g），'
        '碳水 ${result.$1.toStringAsFixed(1)} g/kg（每日 ${dailyCarbs.toStringAsFixed(0)} g）';
  }

  static String _scenarioLabel(bool isStrengthTraining, FitnessGoal goal) {
    if (goal == FitnessGoal.fatLoss && !isStrengthTraining) return '减脂（纯饮食控制）';
    if (goal == FitnessGoal.fatLoss) return '减脂（力量训练）';
    return '增肌（力量训练）';
  }
```

**E) Update `calculateDaily` to take a 3-tuple or add an overload:**

Keep `calculateDaily` as-is since it works with (carbs, protein) pairs. No changes needed.

### 2. /Users/x/FitPlate/lib/screens/profile_screen.dart

Update `_lookupRecommendation()` method:

```dart
  void _lookupRecommendation() {
    final p = widget.profile;
    final isStrengthTraining = !p.noStrengthTraining;
    final h = double.tryParse(_heightCtrl.text) ?? p.height;
    final w = double.tryParse(_weightCtrl.text) ?? p.weight;
    final result = NutritionReference.lookupRecommended(
      isMale: p.gender == Gender.male,
      heightCm: h.round(),
      weightKg: w.round(),
      isStrengthTraining: isStrengthTraining,
      goal: p.goal,
    );
    if (result != null) {
      _recommendedFactor = (result.$1, result.$2);
      _recommendationNote = NutritionReference.recommendationNote(
        isMale: p.gender == Gender.male,
        heightCm: h.round(),
        weightKg: w.round(),
        isStrengthTraining: isStrengthTraining,
        goal: p.goal,
      );
      _hasAppliedRecommendation = true;
      p.proteinPerKg = result.$2;
      p.carbsPerKg = result.$1;
      _proteinKgCtrl.text = result.$2.toStringAsFixed(1);
      _carbsKgCtrl.text = result.$1.toStringAsFixed(1);
      _userTweakedProtein = false;
      _userTweakedCarbs = false;
    } else {
      _recommendedFactor = null;
      _recommendationNote = '当前身高/体重组合暂无参考数据';
      _hasAppliedRecommendation = false;
    }
  }
```

Also, remove the `if (p.noStrengthTraining && p.goal == FitnessGoal.fatLoss)` guard — the method now calls itself whenever the toggle changes, not just for the no-strength case.

Update the `initState` call in profile_screen.dart line ~52 from:
```dart
if (p.noStrengthTraining && p.goal == FitnessGoal.fatLoss) {
  _lookupRecommendation();
}
```
to:
```dart
_lookupRecommendation();
```

### CRITICAL: Add import at top

Add `import '../models/user_profile.dart';` if not already present in nutrition_reference.dart (it uses `FitnessGoal` enum).

That's everything. Do the complete implementation.
