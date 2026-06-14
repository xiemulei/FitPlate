import 'package:flutter/material.dart';
import '../models/food.dart';

class TemplateListScreen extends StatelessWidget {
  final List<Food> foods;
  final List<MealTemplate> templates;

  const TemplateListScreen({
    super.key,
    required this.foods,
    required this.templates,
  });

  Map<Food, double> _calculate(MealTemplate template) {
    return MealCalculator.calculate(
      target: template.target,
      allFoods: foods,
      selected: template.selections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (templates.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('配餐模板')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text('还没有保存的模板', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('先在配餐页面计算结果后保存吧！',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('配餐模板')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          final results = _calculate(template);
          final actualP = results.entries
              .fold(0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
          final actualC = results.entries
              .fold(0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(template.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '目标 ${template.target.protein.toStringAsFixed(0)}P / ${template.target.carbs.toStringAsFixed(0)}C',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
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
                              '${FoodAmountFormatter.formatAmount(e.key, e.value)} (蛋白 ${(e.key.proteinPer100G / 100 * e.value).toStringAsFixed(1)}g, 碳水 ${(e.key.carbsPer100G / 100 * e.value).toStringAsFixed(1)}g)',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    children: [
                      Text(
                          '实际: ${actualP.toStringAsFixed(1)}g 蛋白质 / ${actualC.toStringAsFixed(1)}g 碳水',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
