import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../data/nutrition_reference.dart';

/// 营养参考表底部弹窗
///
/// 展示当前场景下身高×体重的碳水化合物/蛋白质系数矩阵。
class NutritionReferenceSheet {
  static void show(BuildContext context, UserProfile profile) {
    final isMale = profile.gender == Gender.male;
    final isStrengthTraining = !profile.noStrengthTraining;
    final goal = profile.goal;
    final currentHeight = profile.height.round();
    final currentWeight = profile.weight.round();

    final table = NutritionReference.getFullTable(
      isMale: isMale,
      isStrengthTraining: isStrengthTraining,
      goal: goal,
    );
    if (table.isEmpty) return;

    final heights = table.keys.toList()..sort();
    final allWeights = <int>{};
    for (final h in heights) {
      allWeights.addAll(table[h]!.keys);
    }
    final weights = allWeights.toList()..sort();

    final title = NutritionReference.scenarioTitle(
      isMale: isMale,
      isStrengthTraining: isStrengthTraining,
      goal: goal,
    );

    final subtitle = isStrengthTraining
        ? '每格 = 训练日碳水 / 休息日碳水 / 蛋白质 (g/kg)'
        : '每格 = 碳水 / 蛋白质 (g/kg)';
    const cellW = 56.0;
    const labelW = 44.0;
    final rowH = isStrengthTraining ? 58.0 : 48.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final totalWidth = labelW + weights.length * cellW;

        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                              child: Row(children: [
                                SizedBox(
                                  width: labelW,
                                  child: Center(
                                    child: Text('身高↓',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                ...weights.map((w) => SizedBox(
                                      width: cellW,
                                      child: Center(
                                        child: Text('$w',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    )),
                              ]),
                            ),
                            ...heights.map((h) {
                              final isHCur = h == currentHeight;
                              return Container(
                                height: rowH,
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey
                                              .withValues(alpha: 0.12))),
                                ),
                                child: Row(children: [
                                  SizedBox(
                                    width: labelW,
                                    child: Container(
                                      color: isHCur
                                          ? theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.3)
                                          : null,
                                      child: Center(
                                        child: Text('$h',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isHCur
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            )),
                                      ),
                                    ),
                                  ),
                                  ...weights.map((w) {
                                    final val = table[h]?[w];
                                    final isCur =
                                        isHCur && w == currentWeight;
                                    return Container(
                                      width: cellW,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCur
                                            ? theme
                                                .colorScheme.primary
                                                .withValues(alpha: 0.15)
                                            : (val != null
                                                ? Colors.transparent
                                                : Colors.grey
                                                    .withValues(alpha: 0.04)),
                                        border: Border(
                                          left: BorderSide(
                                              color: Colors.grey
                                                  .withValues(alpha: 0.12)),
                                        ),
                                      ),
                                      child: val != null
                                          ? _buildCellContent(
                                              isStrengthTraining,
                                              val,
                                              isCur,
                                              theme,
                                            )
                                          : Center(
                                              child: Text('-',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey[400])),
                                            ),
                                    );
                                  }),
                                ]),
                              );
                            }),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              _legendDot(theme.colorScheme.primary
                                  .withValues(alpha: 0.15)),
                              const SizedBox(width: 4),
                              Text('= 当前位置',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                              const SizedBox(width: 16),
                              _legendDot(
                                  Colors.grey.withValues(alpha: 0.04)),
                              const SizedBox(width: 4),
                              Text('= 无数据',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                            ]),
                          ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  static Widget _buildCellContent(
    bool isStrengthTraining,
    (double, double, double) val,
    bool isCurrent,
    ThemeData theme,
  ) {
    if (isStrengthTraining) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val.$1.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? theme.colorScheme.primary : null,
                height: 1.2,
              )),
          Text(val.$2.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent
                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.grey[500],
                height: 1.3,
              )),
          Text(val.$3.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? theme.colorScheme.primary : null,
                height: 1.2,
              )),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val.$1.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? theme.colorScheme.primary : null,
                height: 1.2,
              )),
          Text(val.$3.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent
                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.grey[500],
                height: 1.2,
              )),
        ],
      );
    }
  }

  static Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }
}
