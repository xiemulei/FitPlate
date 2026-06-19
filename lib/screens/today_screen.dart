import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../services/meal_plan_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// 首页 → 今日配餐 — 自由选食物，自动计算分量
class TodayScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final List<Food> foods;
  final VoidCallback onGoToCycle;
  final VoidCallback onGoToHistory;
  final VoidCallback? onGoToProfile;
  final UserProfile? profile;

  const TodayScreen({
    super.key,
    required this.cycles,
    required this.templates,
    required this.foods,
    required this.onGoToCycle,
    required this.onGoToHistory,
    this.onGoToProfile,
    this.profile,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // 每餐的食物选择 — keyed by "mealIndex"
  final Map<int, List<_FoodServing>> _selections = {};
  int? _expandedMealIndex;
  bool _loaded = false;

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

  /// 自动保存
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

  // ─── 餐食数据 ──────────────────────────────────

  List<_FoodServing> _servings(int mealIdx) =>
      _selections.putIfAbsent(mealIdx, () => []);

  /// 计算某餐所有已选食物的实际碳水和蛋白质
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

  // ─── 优化算法 ──────────────────────────────────

  /// 自动计算每种食物应该吃多少克，使总碳水和总蛋白质尽量接近目标
  /// 同时考虑每种食物对碳水和蛋白质的贡献
  void _autoDistribute(int mealIdx) {
    final meal = _mealsForDay()?[mealIdx];
    if (meal == null) return;
    final servings = _servings(mealIdx);
    if (servings.isEmpty) return;

    final targetCarbs = meal.carbsG.toDouble();
    final targetProtein = meal.proteinG.toDouble();
    final foods = servings.map((s) => s.food).toList();

    final grams = _optimizeGrams(foods, targetCarbs, targetProtein);

    setState(() {
      for (int i = 0; i < servings.length && i < grams.length; i++) {
        servings[i].grams = grams[i].roundToDouble();
        servings[i].updateCtrl();
      }
    });
    _autoSave();
  }

  /// 核心优化函数：先解线性方程组满足碳水，不含碳水的食物按需配蛋白
  List<double> _optimizeGrams(
      List<Food> foods, double targetCarbs, double targetProtein) {
    if (foods.isEmpty) return [];
    final n = foods.length;

    final c = foods.map((f) => f.carbsPer100G / 100).toList();
    final p = foods.map((f) => f.proteinPer100G / 100).toList();

    final result = List.filled(n, 0.0);

    // 区分含碳水和无碳水的食物
    final carbIdx = <int>[];
    final noCarbIdx = <int>[];
    for (int i = 0; i < n; i++) {
      if (c[i] > 0) {
        carbIdx.add(i);
      } else {
        noCarbIdx.add(i);
      }
    }

    // ── 先处理含碳水的食物 ──
    if (carbIdx.isEmpty) {
      // 全是不含碳水的食物（如只选了鸡蛋）→ 按蛋白比例分
      final totalP = p.fold(0.0, (s, v) => s + v);
      if (totalP > 0) {
        final grams = (targetProtein / totalP).clamp(0.0, 2000.0);
        for (int i = 0; i < n; i++) {
          result[i] = grams;
        }
      }
      return result;
    }

    if (carbIdx.length == 1) {
      // 只有一种含碳水食物 → 直接算，不含碳水的单独算
      final ci = carbIdx[0];
      result[ci] = (targetCarbs / c[ci]).clamp(0.0, 2000.0);
      // 这时的蛋白质贡献 = result[ci] * p[ci]
      // 剩余蛋白由无碳水食物按比例分
      final proteinFromCarbs = result[ci] * p[ci];
      final remainingProtein = (targetProtein - proteinFromCarbs).clamp(0.0, targetProtein);
      if (noCarbIdx.isNotEmpty && remainingProtein > 0) {
        final totalNoCarbP = noCarbIdx.fold(0.0, (s, i) => s + p[i]);
        if (totalNoCarbP > 0) {
          // 按蛋白密度分配，不超过合理份量
          for (final i in noCarbIdx) {
            final grams = (remainingProtein / totalNoCarbP).clamp(0.0, 2000.0);
            result[i] = grams;
          }
        }
      }
    } else {
      // 多种含碳水食物 → 按碳水密度加权分配
      final totalC = carbIdx.fold(0.0, (s, i) => s + c[i]);
      final grams = targetCarbs / totalC;
      for (final i in carbIdx) {
        result[i] = grams.clamp(0.0, 2000.0);
      }
      // 无碳水食物的蛋白按比例
      final proteinFromCarbs = carbIdx.fold(0.0, (s, i) => s + result[i] * p[i]);
      final remainingProtein = (targetProtein - proteinFromCarbs).clamp(0.0, targetProtein);
      if (noCarbIdx.isNotEmpty && remainingProtein > 0) {
        final totalNoCarbP = noCarbIdx.fold(0.0, (s, i) => s + p[i]);
        if (totalNoCarbP > 0) {
          for (final i in noCarbIdx) {
            result[i] = (remainingProtein / totalNoCarbP).clamp(0.0, 2000.0);
          }
        }
      }
    }

    return result;
  }

  // ─── 交互 ──────────────────────────────────────

  /// 打开所有食物的选择弹窗，选中即添加到餐次
  void _addFood(int mealIdx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AllFoodPicker(
        foods: widget.foods,
        onPicked: (food) {
          Navigator.pop(ctx);
          // 检查是否已添加过同种食物
          final existing = _servings(mealIdx);
          final dup = existing.where((s) => s.food.id == food.id).firstOrNull;
          if (dup != null) {
            // 已存在，提示
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${food.name} 已添加，可直接修改克数'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
            return;
          }
          setState(() => _servings(mealIdx).add(_FoodServing(food, 0)));
        },
      ),
    );
  }

  void _removeServing(int i, int idx) {
    _servings(i)[idx].dispose();
    setState(() => _servings(i).removeAt(idx));
    _autoSave();
  }

  void _updateGrams(int i, int idx, double grams) {
    setState(() => _servings(i)[idx].grams = grams.roundToDouble());
    _servings(i)[idx].updateCtrl();
    _autoSave();
  }

  void _changeFood(int i, int idx, Food newFood) {
    final sv = _servings(i)[idx];
    sv.dispose();
    setState(() {
      _servings(i)[idx] = _FoodServing(newFood, sv.grams);
    });
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
    final totalCarbs = meals?.fold(0, (s, e) => s + e.carbsG) ?? 0;
    final totalProtein = meals?.fold(0, (s, e) => s + e.proteinG) ?? 0;

    return !_loaded
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 头部 ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isRestDay
                        ? Colors.grey.withValues(alpha: 0.2)
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      isRestDay ? Icons.bedtime : Icons.fitness_center,
                      color:
                          isRestDay ? Colors.grey : theme.colorScheme.primary,
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
                  IconButton(
                    icon: Icon(Icons.history, color: Colors.grey[600]),
                    tooltip: '饮食历史',
                    onPressed: widget.onGoToHistory,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── 新用户引导 ──
              _buildSetupChecklist(theme),

              // ── 今日餐单 ──
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
                          '点击餐次 → 添加食物 → 自动计算分量',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...meals.asMap().entries
                            .map((e) => _buildMealCard(e.key, e.value, theme)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 今日合计 ──
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

  bool get _isProfileSetUp {
    final p = widget.profile;
    if (p == null) return false;
    // 用户修改过默认值就算完成设置
    return p.weight != 70 || p.height != 170;
  }

  Widget _buildSetupChecklist(ThemeData theme) {
    final hasCycle = _activeCycle != null;
    final hasFood = _allSelectedCount > 0;
    final allDone = _isProfileSetUp && hasCycle && hasFood;
    if (allDone) return const SizedBox.shrink();

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('开始使用',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.colorScheme.onPrimaryContainer)),
              const Spacer(),
              Text(
                  '${[_isProfileSetUp, hasCycle, hasFood].where((v) => v).length}/3',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.6))),
            ]),
            const SizedBox(height: 8),
            _checkItem(
              icon: Icons.person,
              label: '填写身体数据',
              done: _isProfileSetUp,
              onTap: widget.onGoToProfile,
            ),
            _checkItem(
              icon: Icons.loop,
              label: '创建训练循环',
              done: hasCycle,
              onTap: widget.onGoToCycle,
            ),
            _checkItem(
              icon: Icons.restaurant,
              label: '今天选食物',
              done: hasFood,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkItem({
    required IconData icon,
    required String label,
    required bool done,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: done ? Colors.green : Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      color: done ? Colors.grey[400] : Colors.grey[700],
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    )),
              ),
              if (done)
                const Icon(Icons.check_circle,
                    size: 18, color: Colors.green)
              else if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
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
              valueColor:
                  AlwaysStoppedAnimation(current >= target ? Colors.green : color),
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
    final carbsRatio = meal.carbsG > 0
        ? (totals.carbs / meal.carbsG).clamp(0.0, 1.0)
        : 0.0;
    final proteinRatio = meal.proteinG > 0
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    _nutChip('C', meal.carbsG, Colors.orange),
                    const SizedBox(width: 4),
                    _nutChip('P', meal.proteinG, Colors.green),
                    const SizedBox(width: 4),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: Colors.grey[500]),
                  ]),
                  // 进度条
                  if (servings.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: carbsRatio,
                              minHeight: 3,
                              backgroundColor: Colors.orange.withValues(alpha: 0.12),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 48,
                          child: Text('${totals.carbs.round()}/${meal.carbsG}',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.orange[600])),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: proteinRatio,
                              minHeight: 3,
                              backgroundColor: Colors.green.withValues(alpha: 0.12),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 48,
                          child: Text(
                              '${totals.protein.round()}/${meal.proteinG}',
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

          // ── 展开区 ──
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 已选食物列表
                  if (servings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('还没选食物，点击下方按钮添加',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[400])),
                    )
                  else ...[
                    ...servings.asMap().entries.map(
                        (e) => _foodRow(i, e.key, e.value, color)),
                    const SizedBox(height: 8),
                    // 当前合计
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calculate, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '碳水 ${totals.carbs.round()}/${meal.carbsG}g · '
                            '蛋白质 ${totals.protein.round()}/${meal.proteinG}g',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 自动计算分量按钮
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: servings.any((s) => s.grams == 0)
                            ? () => _autoDistribute(i)
                            : () => _autoDistribute(i),
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(
                            servings.any((s) => s.grams == 0)
                                ? '自动计算分量'
                                : '重新计算分量'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 添加食物按钮
                  OutlinedButton.icon(
                    onPressed: () => _addFood(i),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加食物'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
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

  Widget _nutChip(String prefix, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$prefix ${value}g',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  // ─── 食物行 ──────────────────────────────────────

  Widget _foodRow(int mealIdx, int idx, _FoodServing sv, Color color) {
    final calcCarbs = sv.food.carbsPer100G / 100 * sv.grams;
    final calcProtein = sv.food.proteinPer100G / 100 * sv.grams;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // 第一行：食物名称 + 切换 + 删除
          Row(
            children: [
              Expanded(
                child: _FoodDropdown(
                  foods: widget.foods,
                  value: sv.food,
                  color: color,
                  onChanged: (f) => _changeFood(mealIdx, idx, f),
                ),
              ),
              GestureDetector(
                onTap: () => _removeServing(mealIdx, idx),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          // 第二行：数量输入 + 营养贡献
          Row(
            children: [
              // 按食物单位显示输入
              if (_isUnitBased(sv.food)) ...[
                // 按个/份/杯显示
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: sv.unitCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w700),
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null && n > 0) {
                        final g = n * sv.food.gramsPerUnit!;
                        _updateGrams(mealIdx, idx, g);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(sv.food.unit.label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
              ] else ...[
                // 按克显示
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: sv.gramCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(
                        fontSize: 14,
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
                const SizedBox(width: 4),
                Text('g',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
              const SizedBox(width: 12),
              Text(
                '碳水 ${calcCarbs.toStringAsFixed(1)}g',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700]),
              ),
              const SizedBox(width: 8),
              Text(
                '蛋白质 ${calcProtein.toStringAsFixed(1)}g',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 工具 ──────────────────────────────────────

  /// 该食物是否按个计（如鸡蛋、蛋白）
  bool _isUnitBased(Food f) =>
      f.unit == FoodUnit.piece &&
      f.gramsPerUnit != null &&
      f.gramsPerUnit! > 0;

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

// ─── 食物下拉框（独立 Widget 避免重建问题）─────────

class _FoodDropdown extends StatelessWidget {
  final List<Food> foods;
  final Food value;
  final Color color;
  final ValueChanged<Food> onChanged;

  const _FoodDropdown({
    required this.foods,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        isExpanded: true,
        value: value.id,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: color),
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
            final food = foods.firstWhere((f) => f.id == fid);
            onChanged(food);
          }
        },
      ),
    );
  }
}

// ─── 内部数据类 ──────────────────────────────────

class _FoodServing {
  Food food;
  double grams;
  late final TextEditingController gramCtrl;
  late final TextEditingController unitCtrl;

  _FoodServing(this.food, this.grams) {
    final isUnit = food.unit == FoodUnit.piece &&
        food.gramsPerUnit != null &&
        food.gramsPerUnit! > 0;
    gramCtrl = TextEditingController(text: grams.round().toString());
    unitCtrl = TextEditingController(
        text: isUnit ? (grams / food.gramsPerUnit!).round().toString() : '');
  }

  static _FoodServing? fromRecord(FoodServingRecord rec, List<Food> allFoods) {
    final food = allFoods.where((f) => f.id == rec.foodId).firstOrNull;
    if (food == null) return null;
    return _FoodServing(food, rec.grams);
  }

  void updateCtrl() {
    gramCtrl.text = grams.round().toString();
    final isUnit = food.unit == FoodUnit.piece &&
        food.gramsPerUnit != null &&
        food.gramsPerUnit! > 0;
    if (isUnit) {
      unitCtrl.text = (grams / food.gramsPerUnit!).round().toString();
    }
  }

  void dispose() {
    gramCtrl.dispose();
    unitCtrl.dispose();
  }
}

// ─── 全部食物选择弹窗 ────────────────────────────

class _AllFoodPicker extends StatefulWidget {
  final List<Food> foods;
  final ValueChanged<Food> onPicked;

  const _AllFoodPicker({required this.foods, required this.onPicked});

  @override
  State<_AllFoodPicker> createState() => _AllFoodPickerState();
}

class _AllFoodPickerState extends State<_AllFoodPicker> {
  late List<_FoodGroup> _groups;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _groups = _buildGroups(widget.foods);
  }

  List<_FoodGroup> _buildGroups(List<Food> foods) {
    // 按 subcategory → 食材名 分组
    final map = <String, List<Food>>{};
    for (final f in foods) {
      final key = f.category;
      map.putIfAbsent(key, () => []).add(f);
    }
    // 主类排序：主食 → 蛋白质 → 其他
    final order = [
      FoodCategory.staple,
      FoodCategory.leanProtein,
      FoodCategory.proteinPowder,
    ];
    final result = <_FoodGroup>[];
    for (final cat in order) {
      if (map.containsKey(cat)) {
        result.add(_FoodGroup(cat, map.remove(cat)!));
      }
    }
    // 剩余的
    for (final entry in map.entries) {
      result.add(_FoodGroup(entry.key, entry.value));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _groups
        : _groups
            .map((g) => _FoodGroup(
                g.name,
                g.foods
                    .where((f) =>
                        f.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList()))
            .where((g) => g.foods.isNotEmpty)
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜食物名称…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.06),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          // 列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: filtered.expand((group) {
                return [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(group.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                        )),
                  ),
                  ...group.foods.map((f) => ListTile(
                        dense: true,
                        title: Text(f.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: Text(
                          '每100g: 碳水${f.carbsPer100G.toStringAsFixed(1)}g · 蛋白${f.proteinPer100G.toStringAsFixed(1)}g',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        trailing: Icon(Icons.add_circle_outline,
                            size: 22, color: Colors.grey[600]),
                        onTap: () => widget.onPicked(f),
                      )),
                  const Divider(height: 1, indent: 16),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodGroup {
  final String name;
  final List<Food> foods;
  _FoodGroup(this.name, this.foods);
}
