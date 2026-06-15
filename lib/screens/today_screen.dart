import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../services/meal_plan_service.dart';
import '../utils/constants.dart';

/// 首页 → 今日配餐 — 循环进度 + 各餐内联选食物
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
  // 当前选中的循环日
  int _selectedDayIndex = 0;

  // 每餐的食物选择
  final Map<int, List<_FoodServing>> _selections = {};
  int? _expandedMealIndex;

  // 分类后的食物
  late List<Food> _carbFoods;
  late List<Food> _proteinFoods;

  @override
  void initState() {
    super.initState();
    final active = widget.cycles.where((c) => c.isActive).firstOrNull;
    if (active?.todayIndex != null) {
      _selectedDayIndex = active!.todayIndex!;
    }
    _carbFoods = widget.foods
        .where((f) => f.category == FoodCategory.staple)
        .toList();
    _proteinFoods = widget.foods
        .where((f) =>
            f.category == FoodCategory.leanProtein ||
            f.category == FoodCategory.proteinPowder)
        .toList();
  }

  List<_FoodServing> _servings(int i) =>
      _selections.putIfAbsent(i, () => []);

  void _addCarb(int i) {
    if (_carbFoods.isEmpty) return;
    final meal = _mealsForDay()?[i];
    if (meal == null) return;
    final food = _carbFoods.first;
    final grams = food.carbsPer100G > 0
        ? (meal.carbsG / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(i).add(_FoodServing(food, grams)));
  }

  void _addProtein(int i) {
    if (_proteinFoods.isEmpty) return;
    final meal = _mealsForDay()?[i];
    if (meal == null) return;
    final food = _proteinFoods.first;
    final grams = food.proteinPer100G > 0
        ? (meal.proteinG / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(i).add(_FoodServing(food, grams)));
  }

  void _removeServing(int i, int idx) =>
      setState(() => _servings(i).removeAt(idx));

  void _updateGrams(int i, int idx, double grams) =>
      setState(() => _servings(i)[idx].grams = grams.roundToDouble());

  void _changeFood(int i, int idx, String foodId, bool isCarb) {
    final foods = isCarb ? _carbFoods : _proteinFoods;
    final food = foods.firstWhere((f) => f.id == foodId);
    final meal = _mealsForDay()![i];
    final newGrams = isCarb
        ? (food.carbsPer100G > 0
            ? (meal.carbsG / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0)
        : (food.proteinPer100G > 0
            ? (meal.proteinG / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0);
    setState(() => _servings(i)[idx] = _FoodServing(food, newGrams));
  }

  ({double carbs, double protein, double grams}) _calcTotals(int i) {
    double carbs = 0, protein = 0, grams = 0;
    for (final s in _servings(i)) {
      grams += s.grams;
      carbs += s.food.carbsPer100G / 100 * s.grams;
      protein += s.food.proteinPer100G / 100 * s.grams;
    }
    return (carbs: carbs, protein: protein, grams: grams);
  }

  bool _isCarbFood(Food f) => f.category == FoodCategory.staple;

  // 计算选中天的配餐
  List<MealPlanEntry>? _mealsForDay() {
    final active = widget.cycles.where((c) => c.isActive).firstOrNull;
    final profile = widget.profile;
    if (active == null || profile == null) return null;
    final day = active.days
        .where((d) => d.dayIndex == _selectedDayIndex)
        .firstOrNull;
    if (day == null) return null;
    return MealPlanService.generateDayMeals(
      isRestDay: day.isRestDay,
      profile: profile,
      trainingTime: active.trainingTime ?? profile.trainingTime,
    );
  }

  // ─── 构建 ────────────────────────────────────────

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

    final selectedDay =
        active.days.where((d) => d.dayIndex == _selectedDayIndex).firstOrNull;
    final todayLabel = selectedDay?.label ?? '第${_selectedDayIndex + 1}天';
    final isRestDay = selectedDay?.isRestDay ?? false;
    final meals = _mealsForDay();

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
                Text(isRestDay ? '休息日' : '训练日',
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
                    final isSelected = d.dayIndex == _selectedDayIndex;
                    final isRest = d.isRestDay;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedDayIndex = d.dayIndex;
                          _expandedMealIndex = null;
                        }),
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
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
                                color: isSelected
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
                    Icon(Icons.circle, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('今天',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── 今日配餐 ──
        if (meals != null && meals.isNotEmpty) ...[
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
                    Text(isRestDay ? '休息日配餐' : '训练日配餐',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    isRestDay ? '点餐选食物，可临时调整' : '点餐选食物，可临时调整',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // ── 各餐 ──
                  ...meals.asMap().entries.map((e) =>
                      _buildMealCard(e.key, e.value, theme)),

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
                            '碳水 ${meals.fold(0, (s, e) => s + e.carbsG)}g',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.orange[700])),
                        const SizedBox(width: 12),
                        Text(
                            '蛋白质 ${meals.fold(0, (s, e) => s + e.proteinG)}g',
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

        // ── 管理循环 ──
        OutlinedButton.icon(
          onPressed: widget.onGoToCycle,
          icon: const Icon(Icons.settings),
          label: const Text('管理循环'),
        ),
      ],
    );
  }

  Widget _buildMealCard(int i, MealPlanEntry meal, ThemeData t) {
    final color = _mealColor(meal.type);
    final icon = _mealIcon(meal.type);
    final isExpanded = _expandedMealIndex == i;
    final servings = _servings(i);
    final totals = _calcTotals(i);
    final carbSvs = servings.where((s) => _isCarbFood(s.food)).toList();
    final proteinSvs = servings.where((s) => !_isCarbFood(s.food)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 餐头（点击展开/收起） ──
          InkWell(
            onTap: () => setState(() {
              _expandedMealIndex = isExpanded ? null : i;
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(meal.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (servings.isNotEmpty)
                  Text('${servings.length}种',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('C ${meal.carbsG}g',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800])),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('P ${meal.proteinG}g',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800])),
                ),
                const SizedBox(width: 4),
                Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[500]),
              ]),
            ),
          ),

          // ── 进度条 ──
          if (servings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                _progressBar(
                    '碳水', totals.carbs, meal.carbsG.toDouble(), Colors.orange),
                const SizedBox(height: 2),
                _progressBar('蛋白质', totals.protein,
                    meal.proteinG.toDouble(), Colors.green),
              ]),
            ),

          // ── 展开：选食物 ──
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌾 碳水主食
                  Row(children: [
                    Icon(Icons.grain, size: 14, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text('碳水主食',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700])),
                  ]),
                  if (carbSvs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('还没选碳水',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ),
                  ...carbSvs.asMap().entries.map(
                      (e) => _foodRow(i, e.key, e.value, true, Colors.orange)),
                  TextButton.icon(
                    onPressed:
                        _carbFoods.isEmpty ? null : () => _addCarb(i),
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text('选碳水主食',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),

                  // 💪 蛋白质
                  Row(children: [
                    Icon(Icons.fitness_center,
                        size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text('蛋白质',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700])),
                  ]),
                  if (proteinSvs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('还没选蛋白质',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ),
                  ...proteinSvs.asMap().entries.map((e) =>
                      _foodRow(i, e.key, e.value, false, Colors.green)),
                  TextButton.icon(
                    onPressed:
                        _proteinFoods.isEmpty ? null : () => _addProtein(i),
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text('选蛋白质',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
            ),
          ],

          // ── 已选合计（底部） ──
          if (servings.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _cmp('碳水', totals.carbs, meal.carbsG.toDouble(), Colors.orange),
                  _cmp('蛋白质', totals.protein, meal.proteinG.toDouble(), Colors.green),
                  _cmp('食物量', totals.grams, 0, Colors.grey, hideTarget: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── 食物行 ──────────────────────────────────────

  Widget _foodRow(
      int mealIdx, int idx, _FoodServing sv, bool isCarb, Color color) {
    final foods = isCarb ? _carbFoods : _proteinFoods;
    final calcCarbs = sv.food.carbsPer100G / 100 * sv.grams;
    final calcProtein = sv.food.proteinPer100G / 100 * sv.grams;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // 下拉选食物
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: sv.food.id,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
                items: foods.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                onChanged: (fid) {
                  if (fid != null)
                    _changeFood(mealIdx, idx, fid, isCarb);
                },
              ),
            ),
          ),
          // 克数输入框
          SizedBox(
            width: 56,
            child: TextField(
              controller:
                  TextEditingController(text: '${sv.grams.round()}'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700),
              onChanged: (v) {
                final g = double.tryParse(v);
                if (g != null && g > 0) {
                  _updateGrams(mealIdx, idx, g);
                }
              },
            ),
          ),
          const SizedBox(width: 2),
          Text('g',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 4),
          // 营养贡献
          Text(isCarb ? '碳${calcCarbs.round()}g' : '蛋${calcProtein.round()}g',
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          // 删除
          GestureDetector(
            onTap: () => _removeServing(mealIdx, idx),
            child: Container(
              padding: const EdgeInsets.all(2),
              child:
                  Icon(Icons.close, size: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 工具组件 ──────────────────────────────────────

  Widget _progressBar(
      String label, double current, double target, Color c) {
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    return Row(
      children: [
        SizedBox(
            width: 28,
            child: Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio > 1.0 ? 1.0 : ratio,
              minHeight: 5,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              valueColor:
                  AlwaysStoppedAnimation(ratio >= 1.0 ? Colors.green : c),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text('${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _cmp(String label, double current, double target, Color c,
      {bool hideTarget = false}) {
    return Column(children: [
      Text('${current.toStringAsFixed(0)}${hideTarget ? "g" : ""}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: current >= target && !hideTarget ? Colors.green : c)),
      if (!hideTarget)
        Text('/ ${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey[400])),
    ]);
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
}

/// 内部数据：一种食物 + 克数
class _FoodServing {
  Food food;
  double grams;
  _FoodServing(this.food, this.grams);
}
