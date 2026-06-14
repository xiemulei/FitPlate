import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../services/meal_plan_service.dart';
import '../widgets/template_meal_card.dart';
import '../utils/meal_utils.dart';

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
    final profile = widget.profile;

    // ── 没有活跃循环 ──
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
            Text('先创建一个循环，然后自动生成配餐计划！',
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

    // ── 有活跃循环 ──
    final todayDay = active.todayDay;
    final todayLabel = todayDay?.label ?? '第${(active.todayIndex ?? 0) + 1}天';
    final isRestDay = todayDay?.isRestDay ?? false;

    // 生成今日配餐目标
    List<MealPlanEntry>? todayMeals;
    if (profile != null) {
      todayMeals = MealPlanService.getTodayMeals(
        activeCycle: active,
        profile: profile,
      );
    }

    // 旧的模板（如果有）
    final template = _findTemplate(todayDay?.mealTemplateId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 头部 ──
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
                Text(isRestDay ? '今天休息' : '练起来！',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('${active.name} · $todayLabel',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),

        // ── 循环进度 ──
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
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
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
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
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
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── 训练时段提示 ──
        if (profile != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(profile.trainingTime.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('训练时段: ${profile.trainingTime.label}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(profile.trainingTime.dietDescription,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                        if (profile.noStrengthTraining) ...[
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

        // ── 今日配餐目标（核心新增） ──
        if (todayMeals != null && todayMeals.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.restaurant_menu,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(isRestDay ? '休息日配餐目标' : '训练日配餐目标',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '每餐目标 = 根据你的体重 × 系数自动计算',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // 各餐目标卡片
                  ...todayMeals.map((meal) {
                    IconData icon;
                    Color color;
                    switch (meal.type) {
                      case MealType.breakfast:
                        icon = Icons.wb_sunny;
                        color = Colors.orange;
                        break;
                      case MealType.postWorkout:
                        icon = Icons.fitness_center;
                        color = Colors.green;
                        break;
                      case MealType.lunch:
                        icon = Icons.restaurant;
                        color = Colors.blue;
                        break;
                      case MealType.dinner:
                        icon = Icons.nights_stay;
                        color = Colors.purple;
                        break;
                      case MealType.snack:
                        icon = Icons.cookie;
                        color = Colors.brown;
                        break;
                      default:
                        icon = Icons.restaurant_menu;
                        color = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(meal.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('碳水 ${meal.carbsG}g',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800])),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('蛋白 ${meal.proteinG}g',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800])),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // 每日合计
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('本日合计  ',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                        Text(
                            '碳水 ${todayMeals.fold(0, (s, e) => s + e.carbsG)}g',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.orange[700])),
                        const SizedBox(width: 12),
                        Text(
                            '蛋白质 ${todayMeals.fold(0, (s, e) => s + e.proteinG)}g',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.green[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── 旧的模板（备选） ──
        if (template != null && todayMeals == null)
          TemplateMealCard(
            template: template,
            results: _calculate(template),
          ),

        const SizedBox(height: 16),

        // ── 管理循环 ──
        OutlinedButton.icon(
          onPressed: widget.onGoToCycle,
          icon: const Icon(Icons.settings),
          label: const Text('管理循环'),
        ),
      ],
    );
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
              Text('自动配餐计划已生成',
                  style: TextStyle(color: Colors.grey[400])),
            ],
          ],
        ),
      ),
    );
  }
}
