import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/user_profile.dart';
import '../data/meal_distribution.dart';
import '../utils/meal_utils.dart';

class MealPlannerScreen extends StatefulWidget {
  final List<Food> foods;
  final List<SelectedFood> selected;
  final ValueChanged<List<SelectedFood>> onSelectedChanged;
  final List<MealTemplate> templates;
  final ValueChanged<MealTemplate> onSaveTemplate;
  final UserProfile? profile;

  const MealPlannerScreen({
    super.key,
    required this.foods,
    required this.selected,
    required this.onSelectedChanged,
    required this.templates,
    required this.onSaveTemplate,
    this.profile,
  });

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  MealType? _selectedType;
  late TextEditingController _pCtrl;
  late TextEditingController _cCtrl;
  final _nameCtrl = TextEditingController();
  bool _showResults = false;
  MealTarget? _currentTarget;

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: '0');
    _cCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _pCtrl.dispose();
    _cCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 根据个人资料自动计算该餐的营养目标
  MealTarget _calculateTarget(MealType type) {
    final profile = widget.profile;
    if (profile == null) return _fallbackTarget(type);

    final isStrengthTraining = !profile.noStrengthTraining;
    final isTrainingDay = isStrengthTraining;

    if (isStrengthTraining) {
      final dist = MealDistributions.forTrainingTime(profile.trainingTime);
      if (dist != null) {
        return dist.calculateTarget(type, profile, isTrainingDay: isTrainingDay);
      }
    } else {
      final portion = MealDistributions.findNoStrengthPortion(type);
      if (portion != null) {
        return MealTarget(
          protein: profile.dailyProtein * portion.proteinRatio,
          carbs: profile.dailyCarbs * portion.carbRatio,
        );
      }
    }
    return _fallbackTarget(type);
  }

  MealTarget _fallbackTarget(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return const MealTarget(protein: 20, carbs: 30);
      case MealType.lunch:
        return const MealTarget(protein: 30, carbs: 40);
      case MealType.dinner:
        return const MealTarget(protein: 25, carbs: 30);
      case MealType.postWorkout:
        return const MealTarget(protein: 30, carbs: 40);
      case MealType.snack:
        return const MealTarget(protein: 15, carbs: 20);
    }
  }

  void _applyMealType(MealType? type) {
    setState(() {
      _selectedType = type;
      if (type != null) {
        final target = _calculateTarget(type);
        _currentTarget = target;
        _pCtrl.text = target.protein.toStringAsFixed(1);
        _cCtrl.text = target.carbs.toStringAsFixed(1);
      }
    });
  }

  void _updateTarget() {
    final p = double.tryParse(_pCtrl.text) ?? 0.0;
    final c = double.tryParse(_cCtrl.text) ?? 0.0;
    _currentTarget = MealTarget(protein: p, carbs: c);
  }

  void _toggleFood(String id) {
    final idx = widget.selected.indexWhere((sf) => sf.foodId == id);
    if (idx >= 0) {
      final updated = [...widget.selected]..removeAt(idx);
      widget.onSelectedChanged(updated);
    } else {
      widget.onSelectedChanged(
          [...widget.selected, SelectedFood(foodId: id, ratio: 1.0)]);
    }
  }

  void _setRatio(String id, double val) {
    final list = widget.selected.map((sf) {
      if (sf.foodId == id)
        return SelectedFood(foodId: id, ratio: val.clamp(0.1, 10.0));
      return sf;
    }).toList();
    widget.onSelectedChanged(list);
  }

  Map<Food, double> _calculate() {
    final target = _currentTarget ?? const MealTarget(protein: 30, carbs: 40);
    return MealCalculator.calculate(
      target: target,
      allFoods: widget.foods,
      selected: widget.selected,
    );
  }

  void _saveTemplate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final target = _currentTarget ?? const MealTarget(protein: 30, carbs: 40);
    widget.onSaveTemplate(MealTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      target: target,
      selections: widget.selected,
    ));
    _nameCtrl.clear();
    setState(() => _showResults = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealTypes = MealType.defaults;

    // 显示个人资料摘要（如果有）
    final profile = widget.profile;
    final hasProfile = profile != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 个人资料摘要 ──
        if (hasProfile) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.person_outline,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${profile.weight.toStringAsFixed(0)}kg · '
                  '蛋${profile.proteinPerKg.toStringAsFixed(1)}g/kg · '
                  '碳${profile.carbsPerKg.toStringAsFixed(1)}g/kg · '
                  '每日 ${profile.dailyProtein.toStringAsFixed(0)}g蛋白 / ${profile.dailyCarbs.toStringAsFixed(0)}g碳水',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // Meal type chips
        Text('选择餐次',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mealTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final mt = mealTypes[i];
              final selected = _selectedType == mt;
              // 如果有 profile，计算该餐的目标值用于预览
              String subtitle;
              if (hasProfile) {
                final t = _calculateTarget(mt);
                subtitle =
                    '${t.protein.toStringAsFixed(0)}P/${t.carbs.toStringAsFixed(0)}C';
              } else {
                final fallback = _fallbackTarget(mt);
                subtitle =
                    '${fallback.protein.toStringAsFixed(0)}P/${fallback.carbs.toStringAsFixed(0)}C';
              }
              return ChoiceChip(
                label: Text(
                  '${mt.label}\n$subtitle',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                selected: selected,
                onSelected: (val) => _applyMealType(val ? mt : null),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Target input
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('营养目标',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (_selectedType != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_selectedType!.label,
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 13))),
                      if (hasProfile && _selectedType != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '基于个人资料自动计算',
                          style: TextStyle(
                              color: Colors.green[400],
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: _pCtrl,
                                decoration: const InputDecoration(
                                    labelText: '蛋白质 (g)',
                                    border: OutlineInputBorder(),
                                    prefixIcon:
                                        Icon(Icons.fitness_center, size: 20)),
                                keyboardType: TextInputType.number,
                                onEditingComplete: _updateTarget)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                controller: _cCtrl,
                                decoration: const InputDecoration(
                                    labelText: '碳水 (g)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.grain, size: 20)),
                                keyboardType: TextInputType.number,
                                onEditingComplete: _updateTarget)),
                      ]),
                    ]))),
        const SizedBox(height: 8),

        // Food selection
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('选择食物',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('点击选择，拖动滑块调整比例',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 8),
                      if (widget.foods.isEmpty)
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                                child: Text('还没有食物，先去食物库添加吧',
                                    style:
                                        TextStyle(color: Colors.grey[500]))))
                      else
                        ...widget.foods.map((food) {
                          final isSel =
                              widget.selected.any((sf) => sf.foodId == food.id);
                          final ratio = widget.selected
                                  .where((sf) => sf.foodId == food.id)
                                  .firstOrNull
                                  ?.ratio ??
                              1.0;
                          return Card(
                            color: isSel
                                ? theme.colorScheme.primaryContainer
                                : null,
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSel
                                      ? theme.colorScheme.primary
                                      : theme
                                          .colorScheme.surfaceContainerHighest,
                                  child: Text(
                                      food.name.isNotEmpty
                                          ? food.name[0]
                                          : '?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSel
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme
                                                  .onSurfaceVariant))),
                              title: Row(
                                children: [
                                  Text(food.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text('(${food.unitLabel})',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11)),
                                ],
                              ),
                              subtitle: Text(
                                  '蛋白 ${food.proteinPer100G.toStringAsFixed(1)} g/100g | 碳水 ${food.carbsPer100G.toStringAsFixed(1)} g/100g',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
                              trailing: isSel
                                  ? SizedBox(
                                      width: 140,
                                      child: Row(children: [
                                        IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 18),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _toggleFood(food.id)),
                                        Text('${ratio.toStringAsFixed(1)}x',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        Expanded(
                                            child: Slider(
                                                value: ratio,
                                                min: 0.1,
                                                max: 5.0,
                                                divisions: 49,
                                                onChanged: (v) =>
                                                    _setRatio(food.id, v))),
                                      ]))
                                  : TextButton.icon(
                                      onPressed: () => _toggleFood(food.id),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('选',
                                          style: TextStyle(fontSize: 13))),
                              onTap: () => _toggleFood(food.id),
                            ),
                          );
                        }),
                    ]))),
        const SizedBox(height: 8),

        // Calculate button
        FilledButton.icon(
          onPressed: widget.selected.isNotEmpty
              ? () => setState(() => _showResults = !_showResults)
              : null,
          icon: Icon(_showResults ? Icons.refresh : Icons.calculate),
          label: Text(_showResults ? '重新计算' : '计算结果'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),

        // Results
        if (_showResults) ..._buildResults(theme),
      ],
    );
  }

  List<Widget> _buildResults(ThemeData theme) {
    final results = _calculate();
    if (results.isEmpty) {
      return [
        const Card(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('请先选择食物'))))
      ];
    }

    final target = _currentTarget ?? const MealTarget(protein: 30, carbs: 40);
    final actualP = results.entries
        .fold(0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
    final actualC = results.entries
        .fold(0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('计算结果',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                  '${results.values.fold(0.0, (s, v) => s + v).toStringAsFixed(0)}g',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary)),
            ]),
            const Divider(),
            ...results.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.key.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Text('(${e.key.unitLabel})',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                          Text(
                              '蛋白 ${(e.key.proteinPer100G / 100 * e.value).toStringAsFixed(1)}g · 碳水 ${(e.key.carbsPer100G / 100 * e.value).toStringAsFixed(1)}g',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ]),
                    Text(
                      FoodAmountFormatter.formatAmount(e.key, e.value),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary),
                    ),
                  ],
                ))),
            const Divider(),
            Row(children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        Text('${actualP.toStringAsFixed(1)}g',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange)),
                        Text(
                            '蛋白质 · 目标 ${target.protein.toStringAsFixed(1)}g',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ]))),
              const SizedBox(width: 8),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        Text('${actualC.toStringAsFixed(1)}g',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.green)),
                        Text('碳水 · 目标 ${target.carbs.toStringAsFixed(1)}g',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ]))),
            ]),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('保存配餐模板'),
                  content: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          hintText: '模板名称（如：减脂午餐）',
                          border: OutlineInputBorder()),
                      autofocus: true),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () {
                          _saveTemplate();
                          Navigator.pop(ctx);
                        },
                        child: const Text('保存')),
                  ],
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存为配餐模板'),
            ),
          ]),
        ),
      ),
    ];
  }
}
