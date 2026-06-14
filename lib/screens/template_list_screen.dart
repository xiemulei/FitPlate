import 'package:flutter/material.dart';
import '../models/food.dart';
import '../utils/meal_utils.dart';
import '../widgets/template_meal_card.dart';

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
          return TemplateMealCard(
            template: template,
            results: results,
          );
        },
      ),
    );
  }
}
