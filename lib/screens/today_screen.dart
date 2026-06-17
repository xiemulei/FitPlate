import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../services/meal_plan_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// 首页 → 今日配餐 — 只显示当天，自动保存饮食记录
class TodayScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final List<Food> foods;
  final VoidCallback onGoToCycle;
  final VoidCallback onGoToHistory;
  final UserProfile? profile;

  const TodayScreen({
    super.key,
    required this.cycles,
    required this.templates,
    required this.foods,
    required this.onGoToCycle,
    required this.onGoToHistory,
    this.profile,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // 每餐的食物选择 — keyed by "mealIndex"
  final Map<int, List<_FoodServing>> _selections = {};
  int? _expandedMealIndex;
  bool _loaded = false; // 是否已加载当日日志

  // 分类后的食物（getter 确保 widget.foods 异步更新后立即生效）
  List<Food> get _carbFoods =>
      widget.foods.where((f) => f.category == FoodCategory.staple).toList();
  List<Food> get _proteinFoods =>
      widget.foods
          .where((f) =>
              f.category == FoodCategory.leanProtein ||
              f.category == FoodCategory.proteinPowder)
          .toList();

  @override
  void didUpdateWidget(TodayScreen old) {
    super.didUpdateWidget(old);
    if (widget.foods != old.foods || widget.cycles != old.cycles) {
      _loadTodayLog();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
  }

  /// 加载今天已保存的饮食记录
  Future<void> _loadTodayLog() async {
    final active = _activeCycle;
    if (active == null) return;

    final todayStr = DailyFoodLog.todayDate();
    final log = await StorageService.loadDailyLog(todayStr);

    if (log != null && mounted) {
      setState(() {
        _selections.clear();
        for (final meal in log.meals) {
          final servings = meal.servings
              .map((s) => _FoodServing.fromRecord(s, widget.foods))
              .where((s) => s != null)
              .cast<_FoodServing>()
              .toList();
          if (servings.isNotEmpty) {
            _selections[meal.mealIndex] = servings;
          }
        }
        _loaded = true;
      });
    } else if (mounted) {
      setState(() => _loaded = true);
    }
  }

  /// 自动保存当前天的选择到持久化
  Future<void> _autoSave() async {
    final active = _activeCycle;
    if (active == null) return;
    final meals = _mealsForDay();
    if (meals == null) return;

    final mealLogs = <MealFoodLog>[];
    for (int i = 0; i < meals.length; i++) {
      final servings = _selections[i] ?? [];
      mealLogs.add(MealFoodLog(
        mealIndex: i,
        mealLabel: meals[i].label,
        targetCarbsG: meals[i].carbsG,
        targetProteinG: meals[i].proteinG,
        servings: servings
            .map((s) => FoodServingRecord(
                  foodId: s.food.id,
                  foodName: s.food.name,
                  grams: s.grams,
                  carbsPer100G: s.food.carbsPer100G,
                  proteinPer100G: s.food.proteinPer100G,
                ))
            .toList(),
      ));
    }

    final todayStr = DailyFoodLog.todayDate();
    final log = DailyFoodLog(
      date: todayStr,
      cycleDayIndex: active.todayIndex ?? 0,
      isRestDay: active.todayDay?.isRestDay ?? false,
      cycleName: active.name,
      meals: mealLogs,
    );
    await StorageService.saveDailyLog(log);
  }

  TrainingCycle? get _activeCycle =>
      widget.cycles.where((c) => c.isActive).firstOrNull;

  bool _isCarbFood(Food f) => f.category == FoodCategory.staple;

  // ─── 餐食数据 ──────────────────────────────────

  List<_FoodServing> _servings(int mealIdx) =>
      _selections.putIfAbsent(mealIdx, () => []);

  double _remainingCarbs(int mealIdx) {
    final meal = _mealsForDay()?[mealIdx];
    if (meal == null) return 0;
    final selected = _servings(mealIdx)
        .where((s) => _isCarbFood(s.food))
        .fold(0.0, (sum, s) => sum + s.food.carbsPer100G / 100 * s.grams);
    return (meal.carbsG - selected).clamp(0.0, meal.carbsG.toDouble());
  }

  double _remainingProtein(int mealIdx) {
    final meal = _mealsForDay()?[mealIdx];
    if (meal == null) return 0;
    final selected = _servings(mealIdx)
        .where((s) => !_isCarbFood(s.food))
        .fold(0.0, (sum, s) => sum + s.food.proteinPer100G / 100 * s.grams);
    return (meal.proteinG - selected).clamp(0.0, meal.proteinG.toDouble());
  }

  ({double carbs, double protein, double grams}) _calcTotals(int mealIdx) {
    double carbs = 0, protein = 0, grams = 0;
    for (final s in _servings(mealIdx)) {
      grams += s.grams;
      carbs += s.food.carbsPer100G / 100 * s.grams;
      protein += s.food.proteinPer100G / 100 * s.grams;
    }
    return (carbs: carbs, protein: protein, grams: grams);
  }

  List<MealPlanEntry>? _mealsForDay() {
    final active = _activeCycle;
    final profile = widget.profile;
    if (active == null || profile == null) return null;
    return MealPlanService.generateDayMeals(
      isRestDay: active.todayDay?.isRestDay ?? false,
      profile: profile,
      trainingTime: active.trainingTime ?? profile.trainingTime,
    );
  }

  // ─── 交互 ──────────────────────────────────────

  void _pickCarb(int mealIdx) async {
    if (_carbFoods.isEmpty) return;
    final meal = _mealsForDay()?[mealIdx];
    if (meal == null) return;

    final food = await showModalBottomSheet<Food>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SimpleFoodPicker(
        foods: _carbFoods,
        title: '选碳水主食',
        color: Colors.orange,
      ),
    );
    if (food == null) return;

    final remaining = _remainingCarbs(mealIdx);
    final target = remaining > 5 ? remaining : meal.carbsG.toDouble();
    final grams = food.carbsPer100G > 0
        ? (target / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(mealIdx).add(_FoodServing(food, grams)));
    _autoSave();
  }

  void _pickProtein(int mealIdx) async {
    if (_proteinFoods.isEmpty) return;
    final meal = _mealsForDay()?[mealIdx];
    if (meal == null) return;

    final food = await showModalBottomSheet<Food>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SimpleFoodPicker(
        foods: _proteinFoods,
        title: '选蛋白质',
        color: Colors.green,
      ),
    );
    if (food == null) return;

    final remaining = _remainingProtein(mealIdx);
    final target = remaining > 5 ? remaining : meal.proteinG.toDouble();
    final grams = food.proteinPer100G > 0
        ? (target / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(mealIdx).add(_FoodServing(food, grams)));
    _autoSave();
  }

  void _removeServing(int i, int idx) {
    _servings(i)[idx].dispose();
    setState(() => _servings(i).removeAt(idx));
    _autoSave();
  }

  void _updateGrams(int i, int idx, double grams) {
    setState(() => _servings(i)[idx].updateGrams(grams));
    _autoSave();
  }

  void _changeFood(int i, int idx, String foodId, bool isCarb) {
    final foods = isCarb ? _carbFoods : _proteinFoods;
    final food = foods.firstWhere((f) => f.id == foodId);
    final meal = _mealsForDay()![i];

    double otherContrib = 0;
    for (int j = 0; j < _servings(i).length; j++) {
      if (j == idx) continue;
      final s = _servings(i)[j];
      if (isCarb && _isCarbFood(s.food)) {
        otherContrib += s.food.carbsPer100G / 100 * s.grams;
      } else if (!isCarb && !_isCarbFood(s.food)) {
        otherContrib += s.food.proteinPer100G / 100 * s.grams;
      }
    }
    final target = isCarb ? meal.carbsG.toDouble() : meal.proteinG.toDouble();
    final remaining = (target - otherContrib).clamp(5.0, target);

    final newGrams = isCarb
        ? (food.carbsPer100G > 0
            ? (remaining / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0)
        : (food.proteinPer100G > 0
            ? (remaining / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0);
    _servings(i)[idx].dispose();
    setState(() => _servings(i)[idx] = _FoodServing(food, newGrams));
    _autoSave();
  }

  // ─── 构建 ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _activeCycle;

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

    final isRestDay = active.todayDay?.isRestDay ?? false;
    final meals = _mealsForDay();
    final totalCarbs =
        meals?.fold(0, (s, e) => s + e.carbsG) ?? 0;
    final totalProtein =
        meals?.fold(0, (s, e) => s + e.proteinG) ?? 0;

    return !_loaded
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 头部：当天概览 ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isRestDay
                        ? Colors.grey.withValues(alpha: 0.2)
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      isRestDay ? Icons.bedtime : Icons.fitness_center,
                      color: isRestDay ? Colors.grey : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isRestDay ? '休息日' : '训练日',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'D${(active.todayIndex ?? 0) + 1} · ${active.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.wifi_tethering,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('共 $totalCarbs g碳水 · $totalProtein g蛋白质',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 历史按钮
                  IconButton(
                    icon: Icon(Icons.history, color: Colors.grey[600]),
                    tooltip: '饮食历史',
                    onPressed: widget.onGoToHistory,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── 今天各餐 ──
              if (meals != null && meals.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('今日餐单',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${_allSelectedCount}种食物',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRestDay ? '休息日 · 点击餐次选食物' : '训练日 · 点击餐次选食物',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...meals.asMap().entries.map(
                            (e) => _buildMealCard(e.key, e.value, theme)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 今日合计卡片 ──
              if (meals != null && meals.isNotEmpty)
                _buildDailySummary(meals, theme),
            ],
          );
  }

  int get _allSelectedCount {
    int count = 0;
    for (final sv in _selections.values) {
      count += sv.length;
    }
    return count;
  }

  Widget _buildDailySummary(List<MealPlanEntry> meals, ThemeData theme) {
    double totalCarbs = 0, totalProtein = 0, totalGrams = 0;
    int mealsWithFood = 0;
    for (final entry in _selections.entries) {
      for (final sv in entry.value) {
        totalCarbs += sv.food.carbsPer100G / 100 * sv.grams;
        totalProtein += sv.food.proteinPer100G / 100 * sv.grams;
        totalGrams += sv.grams;
      }
      if (entry.value.isNotEmpty) mealsWithFood++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.summarize, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text('今日已选合计',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey[700])),
                const Spacer(),
                Text('${mealsWithFood}/${meals.length}餐已填写',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryItem(
                    '碳水', totalCarbs, meals.fold(0, (s, e) => s + e.carbsG).toDouble(),
                    Colors.orange),
                const SizedBox(width: 16),
                _summaryItem(
                    '蛋白质', totalProtein, meals.fold(0, (s, e) => s + e.proteinG).toDouble(),
                    Colors.green),
                const SizedBox(width: 16),
                _summaryItemG('食物量', totalGrams, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      String label, double current, double target, Color color) {
    final ratio =
        target > 0 ? (current / target * 100).clamp(0.0, 150.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: current >= target ? Colors.green : color)),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                  current >= target ? Colors.green : color),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _summaryItemG(String label, double grams, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${grams.round()} g',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ─── 餐卡 ──────────────────────────────────────

  Widget _buildMealCard(int i, MealPlanEntry meal, ThemeData t) {
    final color = _mealColor(meal.type);
    final icon = _mealIcon(meal.type);
    final isExpanded = _expandedMealIndex == i;
    final servings = _servings(i);
    final totals = _calcTotals(i);
    final carbSvs = servings.where((s) => _isCarbFood(s.food)).toList();
    final proteinSvs = servings.where((s) => !_isCarbFood(s.food)).toList();
    final carbsProgress = meal.carbsG > 0
        ? (totals.carbs / meal.carbsG).clamp(0.0, 1.0)
        : 0.0;
    final proteinProgress = meal.proteinG > 0
        ? (totals.protein / meal.proteinG).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 餐头 ──
          InkWell(
            onTap: () => setState(() {
              _expandedMealIndex = isExpanded ? null : i;
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(meal.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    if (servings.isNotEmpty)
                      Text('${servings.length}种',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: Colors.grey[500]),
                  ]),
                  if (servings.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: carbsProgress,
                              minHeight: 3,
                              backgroundColor: Colors.orange.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation(Colors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 40,
                          child: Text('${totals.carbs.round()}/${meal.carbsG}',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.orange[600])),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: proteinProgress,
                              minHeight: 3,
                              backgroundColor: Colors.green.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation(Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 40,
                          child: Text('${totals.protein.round()}/${meal.proteinG}',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.green[600])),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 展开：选食物 ──
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：碳水
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.grain,
                              size: 14, color: Colors.orange[600]),
                          const SizedBox(width: 4),
                          Text('碳水',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700])),
                          const Spacer(),
                          Text(
                            '${totals.carbs.round()}/${meal.carbsG}g',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        if (carbSvs.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Text('还没选碳水',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                          ),
                        ...carbSvs.asMap().entries.map((e) => _foodRow(
                            i, e.key, e.value, true, Colors.orange)),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _carbFoods.isEmpty
                              ? null
                              : () => _pickCarb(i),
                          icon: const Icon(
                              Icons.add_circle_outline, size: 14),
                          label: const Text('选碳水',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右侧：蛋白质
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.fitness_center,
                              size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text('蛋白质',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700])),
                          const Spacer(),
                          Text(
                            '${totals.protein.round()}/${meal.proteinG}g',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        if (proteinSvs.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Text('还没选蛋白质',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                          ),
                        ...proteinSvs.asMap().entries.map((e) => _foodRow(
                            i, e.key, e.value, false, Colors.green)),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _proteinFoods.isEmpty
                              ? null
                              : () => _pickProtein(i),
                          icon: const Icon(
                              Icons.add_circle_outline, size: 14),
                          label: const Text('选蛋白质',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食物名称 + 删除
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: sv.food.id,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color),
                    items: foods
                        .map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (fid) {
                      if (fid != null) {
                        _changeFood(mealIdx, idx, fid, isCarb);
                      }
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeServing(mealIdx, idx),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close,
                      size: 16, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          // 克数 + 营养贡献
          Row(
            children: [
              SizedBox(
                width: 56,
                child: TextField(
                  controller: sv.gramCtrl,
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
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isCarb
                      ? '碳水 ${calcCarbs.round()}g'
                      : '蛋白质 ${calcProtein.round()}g',
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 工具 ──────────────────────────────────────

  IconData _mealIcon(MealType? type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.postWorkout:
        return Icons.fitness_center;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.cookie;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _mealColor(MealType? type) {
    switch (type) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.postWorkout:
        return Colors.green;
      case MealType.lunch:
        return Colors.blue;
      case MealType.dinner:
        return Colors.purple;
      case MealType.snack:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

// ─── 内部数据类 ──────────────────────────────────

class _FoodServing {
  Food food;
  double grams;
  late final TextEditingController gramCtrl;

  _FoodServing(this.food, this.grams) {
    gramCtrl = TextEditingController(text: grams.round().toString());
  }

  /// 从持久化记录恢复（可能因食物 ID 不存在而返回 null）
  static _FoodServing? fromRecord(FoodServingRecord rec, List<Food> allFoods) {
    final food = allFoods.where((f) => f.id == rec.foodId).firstOrNull;
    if (food == null) return null;
    final sv = _FoodServing(food, rec.grams);
    return sv;
  }

  void updateGrams(double v) {
    grams = v.roundToDouble();
    gramCtrl.text = grams.round().toString();
  }

  void dispose() => gramCtrl.dispose();
}

// ─── 食物选择底部弹窗 ────────────────────────────

class _SimpleFoodPicker extends StatelessWidget {
  final List<Food> foods;
  final String title;
  final Color color;

  const _SimpleFoodPicker({
    required this.foods,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: foods.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (ctx, i) {
                final f = foods[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(f.name.isNotEmpty ? f.name[0] : '?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  title: Text(f.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text(
                    '每100g: 碳水${f.carbsPer100G.toStringAsFixed(1)}g · 蛋白${f.proteinPer100G.toStringAsFixed(1)}g',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: Icon(Icons.add_circle_outline,
                      size: 22, color: color),
                  onTap: () => Navigator.pop(context, f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
