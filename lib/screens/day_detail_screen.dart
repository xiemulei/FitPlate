import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../services/meal_plan_service.dart';

/// 某天的完整配餐 + 点餐选食物
class DayDetailScreen extends StatefulWidget {
  final int dayIndex;
  final CycleDay day;
  final TrainingCycle cycle;
  final UserProfile profile;
  final List<Food> foods;

  const DayDetailScreen({
    super.key,
    required this.dayIndex,
    required this.day,
    required this.cycle,
    required this.profile,
    required this.foods,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late List<MealPlanEntry> _meals;
  // 每餐的食物选择：key = "mealType_index"
  final Map<String, List<SelectedFood>> _selections = {};
  // 每餐的展开/收起
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _meals = MealPlanService.generateDayMeals(
      isRestDay: widget.day.isRestDay,
      profile: widget.profile,
      trainingTime: widget.cycle.trainingTime ?? widget.profile.trainingTime,
    );
    for (int i = 0; i < _meals.length; i++) {
      _expanded['meal_$i'] = true;
    }
  }

  String _selectionKey(int index) => '${widget.dayIndex}_$index';

  void _toggleFood(int mealIndex, String foodId) {
    final key = _selectionKey(mealIndex);
    final list = List<SelectedFood>.from(_selections[key] ?? []);
    final idx = list.indexWhere((sf) => sf.foodId == foodId);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(SelectedFood(foodId: foodId, ratio: 1.0));
    }
    _selections[key] = list;
    setState(() {});
  }

  void _setRatio(int mealIndex, String foodId, double val) {
    final key = _selectionKey(mealIndex);
    final list = List<SelectedFood>.from(_selections[key] ?? []);
    final idx = list.indexWhere((sf) => sf.foodId == foodId);
    if (idx >= 0) {
      list[idx] = SelectedFood(foodId: foodId, ratio: val.clamp(0.1, 10.0));
    }
    _selections[key] = list;
    setState(() {});
  }

  /// 计算某餐已选食物的营养素
  ({double proteinG, double carbsG, double amountG}) _calcMealTotals(
      int mealIndex) {
    final key = _selectionKey(mealIndex);
    final sel = _selections[key] ?? [];
    double protein = 0, carbs = 0, amount = 0;
    for (final s in sel) {
      final food = widget.foods.where((f) => f.id == s.foodId).firstOrNull;
      if (food != null) {
        final unitG = food.gramsPerUnit ?? 100.0;
        final g = unitG * s.ratio;
        protein += food.proteinPer100G / 100 * g;
        carbs += food.carbsPer100G / 100 * g;
        amount += g;
      }
    }
    return (proteinG: protein, carbsG: carbs, amountG: amount);
  }

  IconData _mealIcon(MealType? type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_sunny;
      case MealType.postWorkout: return Icons.fitness_center;
      case MealType.lunch: return Icons.restaurant;
      case MealType.dinner: return Icons.nights_stay;
      case MealType.snack: return Icons.cookie;
      default: return Icons.restaurant_menu;
    }
  }

  Color _mealColor(MealType? type) {
    switch (type) {
      case MealType.breakfast: return Colors.orange;
      case MealType.postWorkout: return Colors.green;
      case MealType.lunch: return Colors.blue;
      case MealType.dinner: return Colors.purple;
      case MealType.snack: return Colors.brown;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRestDay = widget.day.isRestDay;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.day.label} · ${isRestDay ? "休息日" : "训练日"}'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 日合计 ──
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(isRestDay ? '休息日配餐目标' : '训练日配餐目标',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _nutrientBadge('碳水',
                        '${_meals.fold(0, (s, e) => s + e.carbsG)}g', Colors.orange),
                    const SizedBox(width: 16),
                    _nutrientBadge('蛋白质',
                        '${_meals.fold(0, (s, e) => s + e.proteinG)}g', Colors.green),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── 各餐 ──
          ..._meals.asMap().entries.map((entry) {
            final i = entry.key;
            final meal = entry.value;
            final color = _mealColor(meal.type);
            final icon = _mealIcon(meal.type);
            final totals = _calcMealTotals(i);
            final isExpanded = _expanded['meal_$i'] ?? false;
            final selList = _selections[_selectionKey(i)] ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 餐头（可点） ──
                  InkWell(
                    onTap: () =>
                        setState(() => _expanded['meal_$i'] = !isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(icon, size: 22, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (selList.isNotEmpty)
                                Text(
                                    '已选 ${selList.length} 种食物',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        // 目标标签
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('C ${meal.carbsG}g',
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
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('P ${meal.proteinG}g',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800])),
                        ),
                      ]),
                    ),
                  ),

                  // ── 进度 ──
                  if (selList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(children: [
                        _progressBar('碳水', totals.carbsG, meal.carbsG.toDouble(),
                            Colors.orange),
                        const SizedBox(height: 4),
                        _progressBar('蛋白质', totals.proteinG,
                            meal.proteinG.toDouble(), Colors.green),
                      ]),
                    ),

                  // ── 展开的食物选择区 ──
                  if (isExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('选择食物（点击切换，拖动调量）',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            ...widget.foods.map((food) {
                              final isSel = selList.any(
                                  (sf) => sf.foodId == food.id);
                              final ratio = selList
                                      .where((sf) => sf.foodId == food.id)
                                      .firstOrNull
                                      ?.ratio ?? 1.0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? color.withValues(alpha: 0.06)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 0),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSel
                                        ? color
                                        : Colors.grey.withValues(alpha: 0.15),
                                    child: Text(food.name.isNotEmpty
                                        ? food.name[0]
                                        : '?'),
                                  ),
                                  title: Text(food.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                    '每${food.unitLabel} 蛋${food.proteinPer100G.toStringAsFixed(1)}g · 碳${food.carbsPer100G.toStringAsFixed(1)}g',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500]),
                                  ),
                                  trailing: isSel
                                      ? SizedBox(
                                          width: 120,
                                          child: Row(children: [
                                            Text('${ratio.toStringAsFixed(1)}x',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Expanded(
                                              child: Slider(
                                                  value: ratio,
                                                  min: 0.1,
                                                  max: 5.0,
                                                  divisions: 49,
                                                  onChanged: (v) =>
                                                      _setRatio(i, food.id, v)),
                                            ),
                                          ]))
                                      : const Icon(Icons.add_circle_outline,
                                          size: 20),
                                  onTap: () => _toggleFood(i, food.id),
                                ),
                              );
                            }),
                            if (widget.foods.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text('先去食物库添加食物吧',
                                      style: TextStyle(
                                          color: Colors.grey[500])),
                                ),
                              ),
                          ]),
                    ),
                  ],

                  // ── 底部：已选合计 + 目标对比 ──
                  if (selList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        border: const Border(
                            top: BorderSide(color: Colors.black12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _compareTile('碳水', totals.carbsG,
                              meal.carbsG.toDouble(), Colors.orange),
                          _compareTile('蛋白质', totals.proteinG,
                              meal.proteinG.toDouble(), Colors.green),
                          _compareTile('食物量', totals.amountG, 0,
                              Colors.grey, hideTarget: true),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _nutrientBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _progressBar(
      String label, double current, double target, Color color) {
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    return Row(
      children: [
        SizedBox(
            width: 32,
            child: Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio > 1.0 ? 1.0 : ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                  ratio >= 1.0 ? Colors.green : color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
            '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _compareTile(
      String label, double current, double target, Color color,
      {bool hideTarget = false}) {
    return Column(children: [
      Text('${current.toStringAsFixed(0)}${hideTarget ? "g" : ""}',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: current >= target && !hideTarget
                  ? Colors.green
                  : color)),
      if (!hideTarget)
        Text('/ ${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
    ]);
  }
}
