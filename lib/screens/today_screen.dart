import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';

class TodayScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final List<Food> foods;
  final VoidCallback onGoToCycle;
  final UserProfile? profile;

  const TodayScreen({
    super.key,
    required this.cycles,
    required this.templates,
    required this.foods,
    required this.onGoToCycle,
    this.profile,
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
    return MealCalculator.calculate(
      target: template.target,
      allFoods: widget.foods,
      selected: template.selections,
    );
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
            Text('今天吃什么？',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('还没有激活的训练循环',
                style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 8),
            Text('先创建一个循环，然后分配配餐模板吧！',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onGoToCycle,
              icon: const Icon(Icons.add),
              label: const Text('创建循环'),
            ),
          ],
        ),
      );
    }

    final todayDay = active.todayDay;
    final todayLabel = todayDay?.label ?? '第${(active.todayIndex ?? 0) + 1}天';
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
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今天吃什么',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('循环: ${active.name} · $todayLabel',
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
                Text('循环进度',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
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
                                color: isToday
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
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
                    Icon(Icons.circle,
                        size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('今天',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 12),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        )),
                    const SizedBox(width: 4),
                    Text('训练日',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 12),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        )),
                    const SizedBox(width: 4),
                    Text('休息日',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Training time suggestion
        if (widget.profile != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(widget.profile!.trainingTime.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('训练时段: ${widget.profile!.trainingTime.label}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(widget.profile!.trainingTime.dietDescription,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                        if (widget.profile!.noStrengthTraining) ...[
                          const SizedBox(height: 4),
                          Text('纯饮食控制模式',
                              style: TextStyle(
                                  color: Colors.orange[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Today's meal
        if (template != null)
          ..._buildMealCard(theme, template)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text('这天还没分配配餐模板',
                        style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('去「循环」页面设置',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: widget.onGoToCycle,
          icon: const Icon(Icons.settings),
          label: const Text('管理循环'),
        ),
      ],
    );
  }

  List<Widget> _buildMealCard(ThemeData theme, MealTemplate template) {
    final results = _calculate(template);
    final actualP = results.entries
        .fold(0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
    final actualC = results.entries
        .fold(0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(template.name,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          FoodAmountFormatter.formatAmount(e.key, e.value),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
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
            Text('第${day.dayIndex + 1}天: ${day.label}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(day.isRestDay ? '休息日' : '训练日',
                style: TextStyle(
                    color: day.isRestDay ? Colors.orange : Colors.green,
                    fontSize: 13)),
            if (template != null) ...[
              const SizedBox(height: 12),
              Text('配餐: ${template.name}',
                  style: TextStyle(color: Colors.grey[400])),
            ] else ...[
              const SizedBox(height: 12),
              Text('未分配配餐模板', style: TextStyle(color: Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }
}
