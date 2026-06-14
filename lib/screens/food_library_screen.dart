import 'package:flutter/material.dart';
import '../models/food.dart';
import '../data/food_data.dart';
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
            Text('还没有食物',
                style:
                    theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('点击右下角 + 添加食物', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => onFoodsChanged(PresetFoods.all),
              icon: const Icon(Icons.download),
              label: const Text('载入预设食物库'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _foodItemCount,
        itemBuilder: (context, index) => _buildRow(context, index),
      ),
    );
  }

  /// 构建的各行：分类标题 / 子类标题 / 食物条目
  List<_RowItem> get _rowItems {
    final items = <_RowItem>[];
    final grouped = PresetFoods.bySubcategory;

    // 按分类 + 子类顺序排列
    for (final cat in PresetFoods.categories) {
      final foodsInCat = _presetFoodsFor(cat, grouped);
      if (foodsInCat.isEmpty) continue;

      // 分类标题
      items.add(_RowItem.header(cat));

      for (final entry in foodsInCat) {
        items.add(_RowItem.subheader(entry.key));
        for (final food in entry.value) {
          items.add(_RowItem.food(food));
        }
      }

      // 分隔
      items.add(_RowItem.divider());
    }

    // 用户自定义食物（未分类的 / 不再预设中的）
    final custom = foods.where((f) => !_presetIds.contains(f.id)).toList();
    for (final cat in _userCategories(custom)) {
      final catFoods = custom.where((f) => f.category == cat).toList();
      items.add(_RowItem.header(cat));
      for (final food in catFoods) {
        items.add(_RowItem.food(food));
      }
      items.add(_RowItem.divider());
    }

    return items;
  }

  int get _foodItemCount => _rowItems.length;

  Widget _buildRow(BuildContext context, int index) {
    final item = _rowItems[index];

    switch (item.type) {
      case _RowType.header:
        return _buildHeader(context, item.label);
      case _RowType.subheader:
        return _buildSubheader(context, item.label);
      case _RowType.food:
        return _buildFoodCard(context, item.food!);
      case _RowType.divider:
        return const SizedBox(height: 4);
    }
  }

  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final icon = _categoryIcon(title);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, Food food) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _categoryColor(food.category, theme),
          child: Text(
            food.name.isNotEmpty ? food.name[0] : '?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(food.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('(${food.unitLabel})',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        subtitle: Text(
          '蛋白质 ${food.proteinPer100G.toStringAsFixed(1)}  碳水 ${food.carbsPer100G.toStringAsFixed(1)}',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
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
            final updated =
                foods.map((f) => f.id == food.id ? result : f).toList();
            onFoodsChanged(updated);
          }
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case '主食':
        return Icons.rice_bowl;
      case '蛋白质-纯瘦肉':
        return Icons.cookie;
      case '蛋白质-蛋白粉':
        return Icons.bolt;
      default:
        return Icons.restaurant;
    }
  }

  Color _categoryColor(String category, ThemeData theme) {
    switch (category) {
      case '主食':
        return Colors.orange.withOpacity(0.2);
      case '蛋白质-纯瘦肉':
        return Colors.red.withOpacity(0.2);
      case '蛋白质-蛋白粉':
        return Colors.purple.withOpacity(0.2);
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Set<String> get _presetIds => PresetFoods.all.map((f) => f.id).toSet();

  /// 获取预设中某分类的子类分组食物
  List<MapEntry<String, List<Food>>> _presetFoodsFor(
      String category, Map<String, List<Food>> grouped) {
    final result = <MapEntry<String, List<Food>>>[];
    final subs = PresetFoods.subcategoriesOf(category);
    if (subs.isNotEmpty) {
      for (final sub in subs) {
        final subFoods = grouped[sub]
            ?.where((f) => foods.any((ff) => ff.id == f.id))
            .toList();
        if (subFoods != null && subFoods.isNotEmpty) {
          result.add(MapEntry(sub, subFoods));
        }
      }
    } else {
      final catFoods = grouped[category]
          ?.where((f) => foods.any((ff) => ff.id == f.id))
          .toList();
      if (catFoods != null && catFoods.isNotEmpty) {
        result.add(MapEntry(category, catFoods));
      }
    }
    return result;
  }

  /// 用户自定义食物的分类（去重，按列表保持顺序）
  List<String> _userCategories(List<Food> custom) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final f in custom) {
      if (seen.add(f.category)) {
        ordered.add(f.category);
      }
    }
    return ordered;
  }
}

enum _RowType { header, subheader, food, divider }

class _RowItem {
  final _RowType type;
  final String label;
  final Food? food;

  _RowItem._(this.type, {this.label = '', this.food});

  factory _RowItem.header(String l) => _RowItem._(_RowType.header, label: l);
  factory _RowItem.subheader(String l) =>
      _RowItem._(_RowType.subheader, label: l);
  factory _RowItem.food(Food f) => _RowItem._(_RowType.food, food: f);
  factory _RowItem.divider() => _RowItem._(_RowType.divider);
}
