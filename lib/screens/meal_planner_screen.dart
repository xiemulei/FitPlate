import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/user_profile.dart';
import '../models/meal_plan_template.dart';
import '../services/storage_service.dart';
import 'meal_plan_editor_screen.dart';

/// 配餐方案库 — 显示预设+用户自定义配餐方案
class MealPlannerScreen extends StatefulWidget {
  final List<Food> foods;
  final UserProfile? profile;

  const MealPlannerScreen({
    super.key,
    required this.foods,
    this.profile,
  });

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<MealPlanTemplate> _userTemplates = [];
  bool _loading = true;

  List<MealPlanTemplate> get _builtIn =>
      MealPlanTemplate.builtIns();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await StorageService.loadMealPlanTemplates();
    setState(() {
      _userTemplates = t;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await StorageService.saveMealPlanTemplates(_userTemplates);
  }

  void _copyTemplate(MealPlanTemplate src) {
    final copy = MealPlanTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${src.name} 副本',
      trainingMeals: src.trainingMeals
          .map((m) => MealSlotDef(
                name: m.name,
                carbRatio: m.carbRatio,
                proteinRatio: m.proteinRatio,
                foods: m.foods.map((f) =>
                    FoodAssignment(foodId: f.foodId, grams: f.grams)).toList(),
              ))
          .toList(),
      restMeals: src.restMeals
          .map((m) => MealSlotDef(
                name: m.name,
                carbRatio: m.carbRatio,
                proteinRatio: m.proteinRatio,
                foods: m.foods.map((f) =>
                    FoodAssignment(foodId: f.foodId, grams: f.grams)).toList(),
              ))
          .toList(),
    );
    _openEditor(copy);
  }

  void _deleteTemplate(MealPlanTemplate t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除方案'),
        content: Text('确定删除「${t.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              setState(() => _userTemplates.removeWhere((x) => x.id == t.id));
              _save();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _openEditor([MealPlanTemplate? existing]) async {
    final result = await Navigator.push<MealPlanTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanEditorScreen(
          template: existing,
          foods: widget.foods,
          profile: widget.profile,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        final idx = _userTemplates.indexWhere((t) => t.id == result.id);
        if (idx >= 0) {
          _userTemplates[idx] = result;
        } else {
          _userTemplates.add(result);
        }
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final builtIn = _builtIn;
    return Scaffold(
      body: _userTemplates.isEmpty && builtIn.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('还没有配餐方案', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('创建方案'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 预设方案
                _sectionHeader('预设方案', Icons.auto_awesome, Colors.blue),
                ...builtIn.map((t) => _builtInCard(t)),
                if (_userTemplates.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionHeader('我的方案', Icons.folder, Colors.green),
                  ..._userTemplates.map((t) => _userCard(t)),
                ],
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('新增方案'),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: color)),
      ]),
    );
  }

  Widget _builtInCard(MealPlanTemplate t) {
    return _templateCard(t, isBuiltIn: true);
  }

  Widget _userCard(MealPlanTemplate t) {
    return _templateCard(t, isBuiltIn: false);
  }

  Widget _templateCard(MealPlanTemplate t, {required bool isBuiltIn}) {
    final icon = t.sourceTime?.icon ?? '📋';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        if (isBuiltIn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('预设',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '🏋️ ${t.trainingMeals.length}餐  ·  😴 ${t.restMeals.length}餐'
                        '${t.trainingMeals.any((m) => m.foods.isNotEmpty) ? "  ·  🍽️ 已配食物" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                if (!isBuiltIn) ...[
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                    onPressed: () => _copyTemplate(t),
                    tooltip: '复制',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
                    onPressed: () => _deleteTemplate(t),
                    tooltip: '删除',
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                    onPressed: () => _copyTemplate(t),
                    tooltip: '复制为副本',
                  ),
                ],
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
