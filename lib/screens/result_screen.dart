import 'package:flutter/material.dart';
import '../models/food.dart';

class ResultScreen extends StatefulWidget {
  final List<Food> foods;
  final MealTarget target;
  final List<SelectedFood> selected;
  final List<MealTemplate> templates;
  final ValueChanged<MealTemplate> onSave;
  final VoidCallback onBack;

  const ResultScreen({
    super.key, required this.foods, required this.target,
    required this.selected, required this.templates,
    required this.onSave, required this.onBack,
  });
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _nameCtrl = TextEditingController();

  Map<Food, double> _calculate() {
    final selFoods = widget.selected.map((sf) {
      final food = widget.foods.firstWhere((f) => f.id == sf.foodId);
      return (food, sf.ratio);
    }).toList();
    final totalWp = selFoods.fold(0.0, (sum, f) => sum + f.$1.proteinPer100G / 100 * f.$2);
    if (totalWp <= 0) return {};
    final k = widget.target.protein / totalWp;
    return {for (final f in selFoods) f.$1: f.$2 * k};
  }

  void _saveTemplate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onSave(MealTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      target: widget.target,
      selections: widget.selected,
    ));
    _nameCtrl.clear();
    Navigator.of(context).pop();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _calculate();
    if (results.isEmpty) {
      return const Center(child: Text('请先在配餐页面选择食物'));
    }

    final actualP = results.entries.fold(0.0, (s, e) => s + e.key.proteinPer100G / 100 * e.value);
    final actualC = results.entries.fold(0.0, (s, e) => s + e.key.carbsPer100G / 100 * e.value);
    final totalG = results.values.fold(0.0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每份克数', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Divider(),
                ...results.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('蛋白质 ${(e.key.proteinPer100G / 100 * e.value).toStringAsFixed(1)}g  ·  碳水 ${(e.key.carbsPer100G / 100 * e.value).toStringAsFixed(1)}g',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                      Text('${e.value.toStringAsFixed(0)}g', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('${actualP.toStringAsFixed(1)}g', style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.orange)),
                            Text('蛋白质 · 目标 ${widget.target.protein.toStringAsFixed(1)}g',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('${actualC.toStringAsFixed(1)}g', style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green)),
                            Text('碳水 · 目标 ${widget.target.carbs.toStringAsFixed(1)}g',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: Text('总重量: ${totalG.toStringAsFixed(0)}g', style: TextStyle(color: Colors.grey[500]))),
              ],
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _showSaveDialog(context),
          icon: const Icon(Icons.save_outlined),
          label: const Text('保存为配餐模板'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('返回调整'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存配餐模板'),
        content: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: '模板名称（如：减脂午餐）', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: _saveTemplate, child: const Text('保存')),
        ],
      ),
    );
  }
}
