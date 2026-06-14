import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../services/meal_plan_service.dart';
import '../utils/constants.dart';

/// 某天的完整配餐——按碳水/蛋白质分类选食物，自动算克数
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

  // 每餐的食物选择 items
  final Map<String, List<_FoodServing>> _selections = {};
  final Map<String, bool> _expanded = {};

  // 分类后的食物列表
  late List<Food> _carbFoods;
  late List<Food> _proteinFoods;

  @override
  void initState() {
    super.initState();
    _meals = MealPlanService.generateDayMeals(
      isRestDay: widget.day.isRestDay,
      profile: widget.profile,
      trainingTime: widget.cycle.trainingTime ?? widget.profile.trainingTime,
    );

    _carbFoods = widget.foods
        .where((f) => f.category == FoodCategory.staple)
        .toList();
    _proteinFoods = widget.foods
        .where((f) =>
            f.category == FoodCategory.leanProtein ||
            f.category == FoodCategory.proteinPowder)
        .toList();

    for (int i = 0; i < _meals.length; i++) {
      _expanded['meal_$i'] = false;
    }
  }

  String _selKey(int i) => '${widget.dayIndex}_$i';
  List<_FoodServing> _servings(int i) =>
      _selections.putIfAbsent(_selKey(i), () => []);

  // ── 添加食物 ──

  void _addCarb(int mealIdx) {
    if (_carbFoods.isEmpty) return;
    final meal = _meals[mealIdx];
    final food = _carbFoods.first;
    final grams = food.carbsPer100G > 0
        ? (meal.carbsG / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(mealIdx).add(_FoodServing(food, grams)));
  }

  void _addProtein(int mealIdx) {
    if (_proteinFoods.isEmpty) return;
    final meal = _meals[mealIdx];
    final food = _proteinFoods.first;
    final grams = food.proteinPer100G > 0
        ? (meal.proteinG / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
        : 100.0;
    setState(() => _servings(mealIdx).add(_FoodServing(food, grams)));
  }

  void _removeServing(int mealIdx, int idx) {
    setState(() => _servings(mealIdx).removeAt(idx));
  }

  void _updateGrams(int mealIdx, int idx, double grams) {
    setState(() => _servings(mealIdx)[idx].grams = grams.roundToDouble());
  }

  void _changeFood(int mealIdx, int idx, String foodId, bool isCarb) {
    final foods = isCarb ? _carbFoods : _proteinFoods;
    final food = foods.firstWhere((f) => f.id == foodId);
    final meal = _meals[mealIdx];
    final newGrams = isCarb
        ? (food.carbsPer100G > 0
            ? (meal.carbsG / food.carbsPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0)
        : (food.proteinPer100G > 0
            ? (meal.proteinG / food.proteinPer100G * 100).clamp(10, 500).roundToDouble()
            : 100.0);
    setState(() {
      _servings(mealIdx)[idx] = _FoodServing(food, newGrams);
    });
  }

  // ── 计算 ──

  ({double carbs, double protein, double grams}) _calcTotals(int mealIdx) {
    double carbs = 0, protein = 0, grams = 0;
    for (final s in _servings(mealIdx)) {
      grams += s.grams;
      carbs += s.food.carbsPer100G / 100 * s.grams;
      protein += s.food.proteinPer100G / 100 * s.grams;
    }
    return (carbs: carbs, protein: protein, grams: grams);
  }

  bool _isCarb(Food f) => f.category == FoodCategory.staple;

  // ─── 构建 ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRestDay = widget.day.isRestDay;
    final totalCarbs = _meals.fold(0, (s, e) => s + e.carbsG);
    final totalProtein = _meals.fold(0, (s, e) => s + e.proteinG);

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
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                    _bigNum('${totalCarbs}g', '碳水', Colors.orange),
                    const SizedBox(width: 16),
                    _bigNum('${totalProtein}g', '蛋白质', Colors.green),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── 各餐 ──
          ..._meals.asMap().entries.map((e) =>
              _buildMealCard(e.key, e.value, theme)),
        ],
      ),
    );
  }

  Widget _bigNum(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _buildMealCard(int i, MealPlanEntry meal, ThemeData t) {
    final color = _mealColor(meal.type);
    final icon = _mealIcon(meal.type);
    final totals = _calcTotals(i);
    final servings = _servings(i);
    final expanded = _expanded['meal_$i'] ?? false;

    // 分组
    final carbSvs =
        servings.asMap().entries.where((e) => _isCarb(e.value.food)).toList();
    final proteinSvs =
        servings.asMap().entries.where((e) => !_isCarb(e.value.food)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 餐头 ──
          InkWell(
            onTap: () =>
                setState(() => _expanded['meal_$i'] = !expanded),
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
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (servings.isNotEmpty)
                        Text('已选 ${servings.length} 种食物',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                _tag('C ${meal.carbsG}g', Colors.orange),
                const SizedBox(width: 6),
                _tag('P ${meal.proteinG}g', Colors.green),
                const SizedBox(width: 4),
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20, color: Colors.grey[500]),
              ]),
            ),
          ),

          // ── 进度条 ──
          if (servings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                _progressBar(
                    '碳水', totals.carbs, meal.carbsG.toDouble(), Colors.orange),
                const SizedBox(height: 4),
                _progressBar('蛋白质', totals.protein,
                    meal.proteinG.toDouble(), Colors.green),
              ]),
            ),

          // ── 展开区：分类选食物 ──
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ 碳水主食 ═══
                  _sectionHeader('碳水主食', Icons.grain, Colors.orange[700]!),
                  if (carbSvs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('还没选碳水，点下面添加',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ),
                  ...carbSvs.map((e) =>
                      _foodRow(i, e.key, e.value, true, Colors.orange)),
                  const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed: _carbFoods.isEmpty ? null : () => _addCarb(i),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('再加一种碳水',
                        style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[700]),
                  ),

                  const Divider(height: 16),

                  // ═══ 蛋白质 ═══
                  _sectionHeader('蛋白质', Icons.fitness_center, Colors.green[700]!),
                  if (proteinSvs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('还没选蛋白质，点下面添加',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ),
                  ...proteinSvs.map((e) =>
                      _foodRow(i, e.key, e.value, false, Colors.green)),
                  const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed:
                        _proteinFoods.isEmpty ? null : () => _addProtein(i),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('再加一种蛋白质',
                        style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],

          // ── 底部：合计对比 ──
          if (servings.isNotEmpty)
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
                  _compareTile('碳水', totals.carbs, meal.carbsG.toDouble(),
                      Colors.orange),
                  _compareTile('蛋白质', totals.protein,
                      meal.proteinG.toDouble(), Colors.green),
                  _compareTile('食物量', totals.grams, 0, Colors.grey,
                      hideTarget: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── 部件 ───────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: color)),
      ]),
    );
  }

  Widget _foodRow(
      int mealIdx, int idx, _FoodServing sv, bool isCarb, Color color) {
    final foods = isCarb ? _carbFoods : _proteinFoods;
    final calcCarbs = sv.food.carbsPer100G / 100 * sv.grams;
    final calcProtein = sv.food.proteinPer100G / 100 * sv.grams;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食物选择行
          Row(
            children: [
              // 下拉框选食物
              Expanded(
                flex: 3,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    value: sv.food.id,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color),
                    items: foods.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.name,
                              style: const TextStyle(fontSize: 13)),
                        )).toList(),
                    onChanged: (fid) {
                      if (fid != null) _changeFood(mealIdx, idx, fid, isCarb);
                    },
                  ),
                ),
              ),
              // 克数滑块
              Expanded(
                flex: 4,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.15),
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: sv.grams.clamp(10, 500),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${sv.grams.round()}g',
                    onChanged: (v) =>
                        _updateGrams(mealIdx, idx, v),
                  ),
                ),
              ),
              // 克数显示
              SizedBox(
                width: 46,
                child: Text('${sv.grams.round()}g',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              // 删除
              GestureDetector(
                onTap: () => _removeServing(mealIdx, idx),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.close, size: 14, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          // 营养贡献
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              children: [
                if (isCarb)
                  Text(
                    '提供碳水 ${calcCarbs.toStringAsFixed(0)}g',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500),
                  ),
                if (!isCarb)
                  Text(
                    '提供蛋白质 ${calcProtein.toStringAsFixed(0)}g',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500),
                  ),
                if (isCarb && sv.food.proteinPer100G > 2)
                  Text(' · 含蛋白 ${calcProtein.toStringAsFixed(0)}g',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500])),
                if (!isCarb && sv.food.carbsPer100G > 2)
                  Text(' · 含碳水 ${calcCarbs.toStringAsFixed(0)}g',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85))),
    );
  }

  Widget _progressBar(String label, double current, double target, Color c) {
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
              valueColor:
                  AlwaysStoppedAnimation(ratio >= 1.0 ? Colors.green : c),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _compareTile(String label, double current, double target, Color c,
      {bool hideTarget = false}) {
    return Column(children: [
      Text('${current.toStringAsFixed(0)}${hideTarget ? "g" : ""}',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color:
                  current >= target && !hideTarget ? Colors.green : c)),
      if (!hideTarget)
        Text('/ ${target.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
