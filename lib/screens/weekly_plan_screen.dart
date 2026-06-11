import 'package:flutter/material.dart';
import '../models/food.dart';

const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const mealNames = ['早餐', '午餐', '晚餐', '加餐'];

class WeeklyPlanScreen extends StatefulWidget {
  final List<WeeklyPlan> plans;
  final List<MealTemplate> templates;
  final ValueChanged<List<WeeklyPlan>> onPlansChanged;

  const WeeklyPlanScreen({
    super.key, required this.plans, required this.templates,
    required this.onPlansChanged,
  });
  @override State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final _nameCtrl = TextEditingController();

  void _createPlan() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onPlansChanged([
      ...widget.plans,
      WeeklyPlan(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name),
    ]);
    _nameCtrl.clear();
    Navigator.of(context).pop();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('还没有周计划', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('先在配餐页面保存模板\n再回来创建周计划吧！',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add), label: const Text('新建周计划'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('周计划', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18), label: const Text('新建'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.plans.map((plan) => _PlanCard(
          plan: plan,
          templates: widget.templates,
          onDelete: () {
            widget.onPlansChanged(widget.plans.where((p) => p.id != plan.id).toList());
          },
          onSlotsChanged: (slots) {
            final updated = widget.plans.map((p) {
              if (p.id == plan.id) return WeeklyPlan(id: p.id, name: p.name, slots: slots);
              return p;
            }).toList();
            widget.onPlansChanged(updated);
          },
        )),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    _nameCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建周计划'),
        content: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: '计划名称（如：减脂第一周）', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: _createPlan, child: const Text('创建')),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WeeklyPlan plan;
  final List<MealTemplate> templates;
  final VoidCallback onDelete;
  final ValueChanged<List<PlanSlot>> onSlotsChanged;

  const _PlanCard({
    required this.plan, required this.templates,
    required this.onDelete, required this.onSlotsChanged,
  });

  Color _getCellColor(int day, int meal) {
    final has = plan.slots.any((s) => s.day == day && s.meal == meal);
    return has ? const Color(0xFF06B6D4).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.08);
  }

  String? _getCellLabel(int day, int meal) {
    final slot = plan.slots.firstWhere(
      (s) => s.day == day && s.meal == meal,
      orElse: () => PlanSlot(day: day, meal: meal, templateId: ''),
    );
    if (slot.templateId.isEmpty) return null;
    return templates.firstWhere(
      (t) => t.id == slot.templateId,
      orElse: () => MealTemplate(id: '', name: '?', target: MealTarget(protein: 0, carbs: 0), selections: []),
    ).name;
  }

  void _editSlot(BuildContext context, int day, int meal) {
    final current = plan.slots.firstWhere(
      (s) => s.day == day && s.meal == meal,
      orElse: () => PlanSlot(day: day, meal: meal, templateId: ''),
    );

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${dayNames[day]} · ${mealNames[meal]}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 16),
            ...templates.map((t) => RadioListTile<String>(
              title: Text(t.name),
              value: t.id,
              groupValue: current.templateId,
              onChanged: (val) {
                final slots = plan.slots.where((s) => !(s.day == day && s.meal == meal)).toList();
                if (val != null && val.isNotEmpty) {
                  slots.add(PlanSlot(day: day, meal: meal, templateId: val));
                }
                onSlotsChanged(slots);
                Navigator.pop(ctx);
              },
            )),
            if (templates.isEmpty)
              const Center(child: Text('还没有配餐模板，先去计算结果页面保存吧', style: TextStyle(color: Colors.grey))),
            if (current.templateId.isNotEmpty) ...[
              const Divider(),
              TextButton.icon(
                onPressed: () {
                  final slots = plan.slots.where((s) => !(s.day == day && s.meal == meal)).toList();
                  onSlotsChanged(slots);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('清空此格', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      ...mealNames.map((m) => SizedBox(
                        width: 80,
                        child: Center(child: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                      )),
                    ],
                  ),
                  // Day rows
                  ...dayNames.asMap().entries.map((entry) {
                    final di = entry.key;
                    return Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(entry.value, textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ),
                        ...[0, 1, 2, 3].map((mi) => GestureDetector(
                          onTap: () => _editSlot(context, di, mi),
                          child: Container(
                            width: 80,
                            height: 44,
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: _getCellColor(di, mi),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Center(
                              child: _getCellLabel(di, mi) != null
                                  ? Text(
                                      _getCellLabel(di, mi)!,
                                      style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    )
                                  : const Icon(Icons.add, size: 16, color: Colors.grey),
                            ),
                          ),
                        )),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
