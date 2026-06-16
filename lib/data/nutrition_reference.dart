import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user_profile.dart';

/// 营养参考数据
///
/// 提供不同场景下的每日碳水化合物/蛋白质摄入量参考（单位：g/kg体重）。
/// 数据从 JSON 资产文件加载，首次使用前需调用 [load]。
class NutritionReference {
  static Map<String, Map<String, Map<String, List<dynamic>?>>>? _data;

  /// 从 JSON 资产文件加载营养参考数据。
  /// 应在 runApp 之前调用。
  static Future<void> load() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/nutrition_reference.json');
    _data = (json.decode(jsonStr) as Map<String, dynamic>).map(
      (k, v) => MapEntry(
          k,
          (v as Map<String, dynamic>).map(
            (hk, hv) => MapEntry(
                hk,
                (hv as Map<String, dynamic>).map(
                  (wk, wv) => MapEntry(wk, wv as List<dynamic>?),
                )),
          )),
    );
  }

  /// 根据条件选择对应的数据表键
  static Map<String, Map<String, List<dynamic>?>>? _selectTable(
    bool isMale,
    bool isStrengthTraining,
    FitnessGoal goal,
  ) {
    if (_data == null) return null;
    final key = !isStrengthTraining
        ? (isMale ? 'nutritionMale' : 'nutritionFemale')
        : goal == FitnessGoal.fatLoss
            ? (isMale ? 'maleFatLoss' : 'femaleFatLoss')
            : (isMale ? 'maleMuscleGain' : 'femaleMuscleGain');
    return _data![key];
  }

  /// 将 JSON List 统一转为 3-tuple 格式。
  /// 2 元素列表 → (carbs, carbs, protein)，3 元素列表 → (trainCarbs, restCarbs, protein)。
  static (double, double, double) _normalizeFactor(List<dynamic> val) {
    final a = (val[0] as num).toDouble();
    final b = (val[1] as num).toDouble();
    if (val.length >= 3) return (a, b, (val[2] as num).toDouble());
    return (a, a, b);
  }

  /// 统一查表方法
  ///
  /// 根据性别、身高、体重、是否做力量训练、健身目标查询对应的系数。
  /// 返回 (训练日碳水, 休息日碳水, 蛋白质) g/kg，或 null（无匹配数据）。
  static (double, double, double)? lookupFactor({
    required bool isMale,
    required int heightCm,
    required int weightKg,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    final table = _selectTable(isMale, isStrengthTraining, goal);
    if (table == null) return null;

    final hStr = heightCm.toString();
    final wStr = weightKg.toString();

    // 尝试精确匹配身高
    final heightData = table[hStr];
    if (heightData != null) {
      final val = heightData[wStr];
      if (val != null) return _normalizeFactor(val);
    }

    // 尝试找最接近的身高，再找最接近的体重
    final sortedHeights = table.keys.toList()..sort((a, b) {
        return (int.parse(a) - heightCm)
            .abs()
            .compareTo((int.parse(b) - heightCm).abs());
      });
    for (final h in sortedHeights) {
      final weightData = table[h]!;
      // 精确体重匹配
      final val = weightData[wStr];
      if (val != null) return _normalizeFactor(val);
      // 最近体重匹配
      final sortedWeights = weightData.keys.toList()..sort((a, b) {
          return (int.parse(a) - weightKg)
              .abs()
              .compareTo((int.parse(b) - weightKg).abs());
        });
      for (final w in sortedWeights) {
        final v = weightData[w];
        if (v != null) return _normalizeFactor(v);
      }
    }

    return null;
  }

  /// 获取推荐因子（训练日碳水 + 休息日碳水 + 蛋白质）
  ///
  /// 返回 (trainCarbsPerKg, restCarbsPerKg, proteinPerKg) 或 null（无匹配）。
  static (double trainCarbsPerKg, double restCarbsPerKg,
      double proteinPerKg)? lookupRecommended({
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
    return (result.$1, result.$2, result.$3);
  }

  /// 获取推荐说明文字
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

    final (trainingCarbs, _, protein) = result;
    final dailyProtein = protein * weightKg.toDouble();
    final dailyCarbs = trainingCarbs * weightKg.toDouble();
    final genderLabel = isMale ? '男' : '女';
    final scenario = _scenarioLabel(isStrengthTraining, goal);

    return '基于$scenario / 身高${heightCm}cm / 体重${weightKg}kg / $genderLabel 推荐：'
        '蛋白质 ${protein.toStringAsFixed(1)} g/kg（每日 ${dailyProtein.toStringAsFixed(0)} g），'
        '碳水 ${trainingCarbs.toStringAsFixed(1)} g/kg（每日 ${dailyCarbs.toStringAsFixed(0)} g）';
  }

  /// 场景标签
  static String _scenarioLabel(bool isStrengthTraining, FitnessGoal goal) {
    if (goal == FitnessGoal.fatLoss && !isStrengthTraining) {
      return '减脂（纯饮食控制）';
    }
    if (goal == FitnessGoal.fatLoss) {
      return '减脂（力量训练）';
    }
    return '增肌（力量训练）';
  }

  /// 获取当前场景下的完整身高×体重对照表。
  ///
  /// 返回 Map<身高cm, Map<体重kg, (训练日碳水, 休息日碳水, 蛋白质)?>>。
  /// null 值表示该身高/体重组合无可参考数据（大多为过轻/过重偏离范围）。
  static Map<int, Map<int, (double, double, double)?>> getFullTable({
    required bool isMale,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    final table = _selectTable(isMale, isStrengthTraining, goal);
    if (table == null) return {};
    final result = <int, Map<int, (double, double, double)?>>{};
    for (final hEntry in table.entries) {
      final h = int.parse(hEntry.key);
      final weightMap = <int, (double, double, double)?>{};
      for (final wEntry in hEntry.value.entries) {
        final w = int.parse(wEntry.key);
        weightMap[w] =
            wEntry.value != null ? _normalizeFactor(wEntry.value!) : null;
      }
      result[h] = weightMap;
    }
    return result;
  }

  /// 获取场景标题文字（如"男性 — 减脂（力量训练）"）
  static String scenarioTitle({
    required bool isMale,
    required bool isStrengthTraining,
    required FitnessGoal goal,
  }) {
    final genderLabel = isMale ? '男性' : '女性';
    return '$genderLabel — ${_scenarioLabel(isStrengthTraining, goal)}';
  }

  /// 根据性别、身高、体重查表获取营养系数（保留向后兼容）
  /// 返回 (carbs_g_per_kg, protein_g_per_kg) 或 null
  static (double, double)? getFactor({
    required bool isMale,
    required int heightCm,
    required int weightKg,
  }) {
    if (_data == null) return null;
    final table = _data![isMale ? 'nutritionMale' : 'nutritionFemale'];
    if (table == null) return null;

    final hStr = heightCm.toString();
    final wStr = weightKg.toString();

    final heightData = table[hStr];
    if (heightData != null) {
      final val = heightData[wStr];
      if (val != null) {
        final n = _normalizeFactor(val);
        return (n.$1, n.$3);
      }
    }

    final sortedHeights = table.keys.toList()..sort((a, b) {
        return (int.parse(a) - heightCm)
            .abs()
            .compareTo((int.parse(b) - heightCm).abs());
      });
    for (final h in sortedHeights) {
      final weightData = table[h];
      if (weightData == null) continue;
      final val = weightData[wStr];
      if (val != null) {
        final n = _normalizeFactor(val);
        return (n.$1, n.$3);
      }
    }
    return null;
  }

  /// 计算每日总需求量
  static ({double carbsG, double proteinG}) calculateDaily({
    required (double carbs, double protein) factor,
    required double weightKg,
  }) {
    return (
      carbsG: factor.$1 * weightKg,
      proteinG: factor.$2 * weightKg,
    );
  }
}
