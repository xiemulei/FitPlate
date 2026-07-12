import 'package:flutter/material.dart';
import '../models/food.dart';
import '../utils/meal_utils.dart';

/// 统一的模板膳食卡片组件 — 显示模板名称、食物列表和营养摘要
class TemplateMealCard extends StatelessWidget {
  final MealTemplate template;
  final Map<Food, double> results;
  final VoidCallback? onSave;
  final bool showSaveButton;

  const TemplateMealCard({
    super.key,
    required this.template,
    required this.results,
    this.onSave,
    this.showSaveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = MealCalculator.calculateActual(results);
    final totalG = results.values.fold(0.0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + target badge
            Row(
              children: [
                Icon(Icons.restaurant_menu,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(template.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '目标 ${template.target.carbs.toStringAsFixed(0)}C / ${template.target.protein.toStringAsFixed(0)}P',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Food list
            ...results.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(e.key.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Text('(${e.key.unitLabel})',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                      Text(
                        FoodAmountFormatter.formatAmount(e.key, e.value),
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            // Nutrition summary
            Row(
              children: [
                _NutrientBadge(
                  label: '蛋白质',
                  value: '${actual.protein.toStringAsFixed(1)}g',
                  color: Colors.orange,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _NutrientBadge(
                  label: '碳水',
                  value: '${actual.carbs.toStringAsFixed(1)}g',
                  color: Colors.green,
                  theme: theme,
                ),
                const Spacer(),
                Text('共 ${totalG.toStringAsFixed(0)}g',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            // Save button
            if (showSaveButton && onSave != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存为配餐模板'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _NutrientBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }
}
