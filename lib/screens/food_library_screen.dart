import 'package:flutter/material.dart';
import '../models/food.dart';
import 'food_detail_screen.dart';

class FoodLibraryScreen extends StatelessWidget {
  final List<Food> foods;
  final ValueChanged<List<Food>> onFoodsChanged;

  const FoodLibraryScreen({
    super.key,
    required this.foods,
    required this.onFoodsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('还没有食物', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('点击右下角 + 添加食物', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  food.name.isNotEmpty ? food.name[0] : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '蛋白质 ${food.proteinPer100G.toStringAsFixed(1)} g/100g    碳水 ${food.carbsPer100G.toStringAsFixed(1)} g/100g',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push<Food>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(
                      food: food,
                      onDeleted: () {
                        final updated = foods.where((f) => f.id != food.id).toList();
                        onFoodsChanged(updated);
                      },
                    ),
                  ),
                );
                if (result != null) {
                  final updated = foods.map((f) => f.id == food.id ? result : f).toList();
                  onFoodsChanged(updated);
                }
              },
            ),
          );
        },
      ),
    );
  }
}