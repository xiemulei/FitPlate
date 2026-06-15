import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/user_profile.dart';
import '../models/meal_plan_template.dart';
import '../utils/constants.dart';

/// 配餐方案编辑器 — 查看/编辑方案名称、各餐配比、已选食物
class MealPlanEditorScreen extends StatefulWidget {
  final MealPlanTemplate? template;
  final List<Food> foods;
  final UserProfile? profile;

  const MealPlanEditorScreen({
    super.key,
    this.template,
    required this.foods,
    this.profile,
  });

  @override
  State<MealPlanEditorScreen> createState() => _MealPlanEditorScreenState();
}

class _MealPlanEditorScreenState extends State<MealPlanEditorScreen> {
  late TextEditingController _nameCtrl;
  late MealPlanTemplate _t;
  bool _isTraining = true; // 当前显示训练日还是休息日

  @override
  void initState() {
    super.initState();
    final src = widget.template;
    if (src != null) {
      _t = src;
    } else {
      // 新建：默认用午饭后练的配比
      _t = MealPlanTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '我的方案',
        trainingMeals: [
          MealSlotDef(name: '早饭', carbRatio: 0.20, proteinRatio: 0.20),
          MealSlotDef(name: '午饭=练前餐', carbRatio: 0.15, proteinRatio: 0.00),
          MealSlotDef(name: '练后餐', carbRatio: 0.35, proteinRatio: 0.30),
          MealSlotDef(name: '晚饭', carbRatio: 0.20, proteinRatio: 0.30),
          MealSlotDef(name: '零食/夜宵', carbRatio: 0.10, proteinRatio: 0.20),
        ],
        restMeals: [
          MealSlotDef(name: '早饭', carbRatio: 0.20, proteinRatio: 0.20),
          MealSlotDef(name: '午饭', carbRatio: 0.35, proteinRatio: 0.30),
          MealSlotDef(name: '晚饭', carbRatio: 0.35, proteinRatio: 0.30),
          MealSlotDef(name: '零食/夜宵', carbRatio: 0.10, proteinRatio: 0.20),
        ],
      );
    }
    _nameCtrl = TextEditingController(text: _t.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<MealSlotDef> get _meals => _isTraining ? _t.trainingMeals : _t.restMeals;

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    _t.name = name;
    Navigator.pop(context, _t);
  }

  void _addMeal() {
    setState(() {
      final slot = MealSlotDef(name: '新餐次', carbRatio: 0.10, proteinRatio: 0.10);
      if (_isTraining) {
        _t.trainingMeals.add(slot);
      } else {
        _t.restMeals.add(slot);
      }
    });
  }

  void _removeMeal(int idx) {
    setState(() {
      if (_isTraining) {
        _t.trainingMeals.removeAt(idx);
      } else {
        _t.restMeals.removeAt(idx);
      }
    });
  }

  void _pickFood(int mealIdx) async {
    final currentFoods = _meals[mealIdx].foods;
    // 显示食物选择底部弹窗
    final result = await showModalBottomSheet<List<FoodAssignment>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FoodPickerSheet(
        foods: widget.foods,
        current: currentFoods,
      ),
    );
    if (result != null) {
      setState(() {
        _meals[mealIdx].foods = result;
      });
    }
  }

  // 计算某餐按 profile 的实际克数
  String _calcGrams(MealSlotDef m) {
    final p = widget.profile;
    if (p == null) return '';
    final c = (p.dailyCarbs * m.carbRatio).round();
    final pr = (p.dailyProtein * m.proteinRatio).round();
    return '≈ ${c}g碳 / ${pr}g蛋';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = _meals;
    final profile = widget.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? '编辑方案' : '新建方案'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 名称 ──
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '方案名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // ── 个人资料摘要 ──
          if (profile != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${profile.weight.toStringAsFixed(0)}kg · '
                    '每日 ${profile.dailyProtein.toStringAsFixed(0)}g蛋白 / ${profile.dailyCarbs.toStringAsFixed(0)}g碳水',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 12),

          // ── Tab: 训练日/休息日 ──
          Row(children: [
            Expanded(
              child: _tabBtn('🏋️ 训练日', _isTraining, () => setState(() => _isTraining = true)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tabBtn('😴 休息日', !_isTraining, () => setState(() => _isTraining = false)),
            ),
          ]),
          const SizedBox(height: 12),

          // ── 各餐列表 ──
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('还没有餐次，点下面添加',
                    style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            ...meals.asMap().entries.map((e) => _mealCard(e.key, e.value, theme)),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addMeal,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加餐次'),
          ),
          const SizedBox(height: 24),

          // ── 合计检查 ──
          _totalCheck(meals, theme),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _mealCard(int idx, MealSlotDef m, ThemeData theme) {
    final cRatio = (m.carbRatio * 100).round();
    final pRatio = (m.proteinRatio * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：编号 + 餐名 + 删除
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${idx + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: m.name),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '餐次名称',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    onChanged: (v) => m.name = v,
                  ),
                ),
                if (_meals.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red[300]),
                    onPressed: () => _removeMeal(idx),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            // 比例滑块
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('碳水 $cRatio%',
                        style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                    Slider(
                      value: m.carbRatio,
                      min: 0,
                      max: 0.6,
                      divisions: 60,
                      activeColor: Colors.orange,
                      onChanged: (v) => setState(() => m.carbRatio = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('蛋白质 $pRatio%',
                        style: TextStyle(fontSize: 11, color: Colors.green[700])),
                    Slider(
                      value: m.proteinRatio,
                      min: 0,
                      max: 0.6,
                      divisions: 60,
                      activeColor: Colors.green,
                      onChanged: (v) => setState(() => m.proteinRatio = v),
                    ),
                  ],
                ),
              ),
            ]),

            // 实际克数（有 profile 时）
            if (widget.profile != null)
              Text(_calcGrams(m),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),

            // 已选食物
            if (m.foods.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: m.foods.map((fa) {
                  final food = widget.foods.where((f) => f.id == fa.foodId).firstOrNull;
                  return Chip(
                    label: Text(food?.name ?? fa.foodId,
                        style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => m.foods.removeWhere((x) => x.foodId == fa.foodId));
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _pickFood(idx),
              icon: Icon(Icons.restaurant_menu, size: 16,
                  color: m.foods.isNotEmpty ? theme.colorScheme.primary : Colors.grey),
              label: Text(m.foods.isNotEmpty ? '更换食物' : '选择食物',
                  style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalCheck(List<MealSlotDef> meals, ThemeData theme) {
    final totalC = meals.fold(0.0, (s, m) => s + m.carbRatio);
    final totalP = meals.fold(0.0, (s, m) => s + m.proteinRatio);
    final okC = (totalC - 1.0).abs() < 0.02;
    final okP = (totalP - 1.0).abs() < 0.02;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: okC && okP ? Colors.green.withValues(alpha: 0.06) : Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: okC && okP ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Icon(
          okC && okP ? Icons.check_circle : Icons.warning_amber,
          size: 18,
          color: okC && okP ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                okC && okP ? '比例合计正确' : '比例未合计到 100%',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: okC && okP ? Colors.green[700] : Colors.orange[700]),
              ),
              Text(
                '碳水合计 ${(totalC * 100).round()}% · 蛋白质合计 ${(totalP * 100).round()}%',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// 食物选择底部弹窗
class _FoodPickerSheet extends StatefulWidget {
  final List<Food> foods;
  final List<FoodAssignment> current;

  const _FoodPickerSheet({required this.foods, required this.current});

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  late List<FoodAssignment> _selected;
  // 按分类分组
  late Map<String, List<Food>> _carbFoods;
  late Map<String, List<Food>> _proteinFoods;

  @override
  void initState() {
    super.initState();
    _selected = widget.current
        .map((f) => FoodAssignment(foodId: f.foodId, grams: f.grams))
        .toList();

    _carbFoods = {};
    _proteinFoods = {};
    for (final f in widget.foods) {
      if (f.category == FoodCategory.staple) {
        _carbFoods.putIfAbsent(f.subcategory ?? '主食', () => []).add(f);
      } else if (f.category == FoodCategory.leanProtein ||
          f.category == FoodCategory.proteinPowder) {
        _proteinFoods.putIfAbsent(f.category, () => []).add(f);
      }
    }
  }

  void _toggle(String foodId, double proteinPer100G, double carbsPer100G) {
    setState(() {
      final idx = _selected.indexWhere((s) => s.foodId == foodId);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        // 默认 100g
        _selected.add(FoodAssignment(foodId: foodId, grams: 100));
      }
    });
  }

  void _updateGrams(String foodId, double grams) {
    setState(() {
      final idx = _selected.indexWhere((s) => s.foodId == foodId);
      if (idx >= 0) _selected[idx].grams = grams.roundToDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 顶部
          Row(children: [
            const Text('选择食物', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('确定 (${_selected.length})'),
            ),
          ]),
          const SizedBox(height: 8),

          // 已选摘要
          if (_selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selected.map((s) {
                  final food = widget.foods.where((f) => f.id == s.foodId).firstOrNull;
                  return Chip(
                    label: Text('${food?.name ?? s.foodId} ${s.grams.round()}g',
                        style: const TextStyle(fontSize: 11)),
                    onDeleted: () => _toggle(s.foodId, 0, 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),

          // 食物列表
          Expanded(
            child: ListView(
              children: [
                _foodGroup('🌾 碳水主食', _carbFoods, Colors.orange),
                const Divider(height: 16),
                _foodGroup('🥩 蛋白质', _proteinFoods, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodGroup(
      String title, Map<String, List<Food>> groups, Color color) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        ...groups.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ...entry.value.map((f) => _foodItem(f, color)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _foodItem(Food food, Color color) {
    final sel = _selected.where((s) => s.foodId == food.id).firstOrNull;
    final isSel = sel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSel ? color.withValues(alpha: 0.06) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor:
              isSel ? color : Colors.grey.withValues(alpha: 0.12),
          child: Text(food.name.isNotEmpty ? food.name[0] : '?',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : Colors.grey[600])),
        ),
        title: Row(children: [
          Text(food.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          if (isSel) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: Slider(
                value: sel.grams.clamp(10, 500),
                min: 10,
                max: 500,
                divisions: 49,
                label: '${sel.grams.round()}g',
                onChanged: (v) => _updateGrams(food.id, v),
              ),
            ),
            Text('${sel.grams.round()}g',
                style: TextStyle(fontSize: 11, color: color)),
          ],
        ]),
        subtitle: Text(
          '每100g: 蛋白${food.proteinPer100G.toStringAsFixed(1)}g · 碳水${food.carbsPer100G.toStringAsFixed(1)}g',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
        trailing: isSel
            ? Icon(Icons.check_circle, size: 20, color: color)
            : const Icon(Icons.add_circle_outline, size: 20),
        onTap: () => _toggle(food.id, food.proteinPer100G, food.carbsPer100G),
      ),
    );
  }
}
