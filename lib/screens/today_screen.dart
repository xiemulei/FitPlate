import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/cycle.dart';

class TodayScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final List<Food> foods;
  final VoidCallback onGoToCycle;

  const TodayScreen({
    super.key,
    required this.cycles,
    required this.templates,
    required this.foods,
    required this.onGoToCycle,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  MealTemplate? _findTemplate(String? id) {
    if (id == null) return null;
    try {
      return widget.templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<Food, double> _calculate(MealTemplate template) {
    final selFoods = template.selections.map((sf) {
      final food = widget.foods.firstWhere((f) => f.id == sf.foodId,
          orElse: () => Food(id: '', name: '\u672a\u77e5', proteinPer100G: 0, carbsPer100G: 0));
      return (food, sf.ratio);
    }).toList();
    final totalWp = selFoods.fold(0.0, (sum, f) => sum + f.$1.proteinPer100G / 100 * f.$2);
    if (totalWp <= 0) return {};
    final k = template.target.protein / totalWp;
    return {for (final f in selFoods) f.$1: f.$2 * k};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.cycles.where((c) => c.isActive).firstOrNull;

    if (active == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today, size: 72, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('\u4eca\u5929\u5403\u4ec0\u4e48\uff1f',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('\u8fd8\u6ca1\u6709\u6fc0\u6d3b\u7684\u8bad\u7ec3\u5faa\u73af',
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 8),
            Text('\u5148\u521b\u5efa\u4e00\u4e2a\u5faa\u73af\uff0c\u7136\u540e\u5206\u914d\u914d\u9910\u6a21\u677f\u5427\uff01',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onGoToCycle,
              icon: const Icon(Icons.add),
              label: const Text('\u521b\u5efa\u5faa\u73af'),
            ),
          ],
        ),
      );
    }

    final todayDay = active.todayDay;
    final todayLabel = todayDay?.label ?? '\u7b2c${(active.todayIndex ?? 0) + 1}\u5929';
    final template = _findTemplate(todayDay?.mealTemplateId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u4eca\u5929\u5403\u4ec0\u4e48',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text('\u5faa\u73af: ${active.name} \u00b7 $todayLabel',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),

        // Cycle progress
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u5faa\u73af\u8fdb\u5ea6', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: active.days.map((d) {
                    final isToday = d.dayIndex == (active.todayIndex ?? -1);
                    final isRest = d.isRestDay;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showDayDetail(context, active, d),
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primary
                                : isRest
                                    ? Colors.grey.withValues(alpha: 0.15)
                                    : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'D${d.dayIndex + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('\u4eca\u5929', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 12),
                    Container(width: 12, height: 12, decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    )),
                    const SizedBox(width: 4),
                    Text('\u8bad\u7ec3\u65e5', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 12),
                    Container(width: 12, height: 12, decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    )),
                    const SizedBox(width: 4),
                    Text('\u4f11\u606f\u65e5', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Today's meal
        if (template != null) ..._buildMealCard(theme, template) else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 40, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  Text('\u8fd9\u5929\u8fd8\u6ca1\u5206\u914d\u914d\u9910\u6a21\u677f',
                    style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Text('\u53bb\u300c\u5faa\u73af\u300d\u9875\u9762\u8bbe\u7f6e',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: widget.onGoToCycle,
          icon: const Icon(Icons.settings),
          label: const Text('\u7ba1\u7406\u5faa\u73af'),
        ),
      ],
    );
  }

  List<Widget> _buildMealCard(ThemeData theme, MealTemplate template) {
    final results = _calculate(template);
    final actualP = results.entries.fold(0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
    final actualC = results.entries.fold(0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(template.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\u76ee\u6807 ${template.target.protein.toStringAsFixed(0)}P / ${template.target.carbs.toStringAsFixed(0)}C',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
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
                    Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${e.value.toStringAsFixed(0)}g',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              )),
              const Divider(),
              Row(
                children: [
                  Text('\u5b9e\u9645: ${actualP.toStringAsFixed(1)}g \u86cb\u767d\u8d28 / ${actualC.toStringAsFixed(1)}g \u78b3\u6c34',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _showDayDetail(BuildContext context, TrainingCycle cycle, CycleDay day) {
    final template = _findTemplate(day.mealTemplateId);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\u7b2c${day.dayIndex + 1}\u5929: ${day.label}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(day.isRestDay ? '\u4f11\u606f\u65e5' : '\u8bad\u7ec3\u65e5',
              style: TextStyle(color: day.isRestDay ? Colors.orange : Colors.green, fontSize: 13)),
            if (template != null) ...[
              const SizedBox(height: 12),
              Text('\u914d\u9910: ${template.name}', style: TextStyle(color: Colors.grey[400])),
            ] else ...[
              const SizedBox(height: 12),
              Text('\u672a\u5206\u914d\u914d\u9910\u6a21\u677f', style: TextStyle(color: Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }
}
