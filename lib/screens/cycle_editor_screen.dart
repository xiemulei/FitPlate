import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/cycle.dart';

/// 训练循环编辑器 — 独立页面编辑循环名称和各天的标签/配餐
class CycleEditorScreen extends StatefulWidget {
  final TrainingCycle cycle;
  final List<MealTemplate> templates;
  final ValueChanged<TrainingCycle> onSave;

  const CycleEditorScreen({
    super.key,
    required this.cycle,
    required this.templates,
    required this.onSave,
  });

  @override
  State<CycleEditorScreen> createState() => _CycleEditorScreenState();
}

class _CycleEditorScreenState extends State<CycleEditorScreen> {
  late TrainingCycle _cycle;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _cycle = widget.cycle;
    _nameCtrl = TextEditingController(text: _cycle.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onSave(_cycle.copyWith(name: name));
  }

  void _editDay(BuildContext context, CycleDay day) {
    final labelCtrl = TextEditingController(text: day.label);
    bool isRestDay = day.isRestDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑第${day.dayIndex + 1}天'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '如：胸肌日、背日',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('休息日'),
                subtitle: Text(isRestDay ? '这天不用训练' : '训练日',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                value: isRestDay,
                activeColor: Colors.orange,
                onChanged: (v) => setDialogState(() => isRestDay = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  setState(() {
                    _cycle = _cycle.copyWith(
                        days: _cycle.days.map((d) {
                      if (d.dayIndex == day.dayIndex) {
                        return CycleDay(
                          dayIndex: d.dayIndex,
                          label: labelCtrl.text.trim().isEmpty
                              ? d.label
                              : labelCtrl.text.trim(),
                          isRestDay: isRestDay,
                          mealTemplateId: d.mealTemplateId,
                        );
                      }
                      return d;
                    }).toList());
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('确定')),
          ],
        ),
      ),
    );
  }

  void _pickTemplate(BuildContext context, CycleDay day) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('第${day.dayIndex + 1}天: ${day.label} — 选择配餐',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 16),
            if (widget.templates.isEmpty)
              const Center(
                  child: Text('还没有配餐模板，先去配餐页面保存吧',
                      style: TextStyle(color: Colors.grey)))
            else ...[
              RadioListTile<String?>(
                title: const Text('不分配'),
                value: null,
                groupValue: day.mealTemplateId,
                onChanged: (val) {
                  setState(() {
                    _cycle = _cycle.copyWith(
                        days: _cycle.days.map((d) {
                      if (d.dayIndex == day.dayIndex) {
                        return d.copyWith(mealTemplateId: null);
                      }
                      return d;
                    }).toList());
                  });
                  Navigator.pop(ctx);
                },
              ),
              ...widget.templates.map((t) => RadioListTile<String>(
                    title: Text(t.name),
                    subtitle: Text(
                        '目标 ${t.target.protein.toStringAsFixed(0)}P / ${t.target.carbs.toStringAsFixed(0)}C'),
                    value: t.id,
                    groupValue: day.mealTemplateId,
                    onChanged: (val) {
                      setState(() {
                        _cycle = _cycle.copyWith(
                            days: _cycle.days.map((d) {
                          if (d.dayIndex == day.dayIndex) {
                            return d.copyWith(mealTemplateId: val);
                          }
                          return d;
                        }).toList());
                      });
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final updated = List<CycleDay>.from(_cycle.days);
      final item = updated.removeAt(oldIndex);
      updated.insert(
          newIndex,
          CycleDay(
            dayIndex: newIndex,
            label: item.label,
            isRestDay: item.isRestDay,
            mealTemplateId: item.mealTemplateId,
          ));
      updated.asMap().forEach((i, d) {
        updated[i] = CycleDay(
          dayIndex: i,
          label: d.label,
          isRestDay: d.isRestDay,
          mealTemplateId: d.mealTemplateId,
        );
      });
      _cycle = _cycle.copyWith(days: updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑循环'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '循环名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Stats
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _statChip(Icons.calendar_view_day, '${_cycle.cycleLength}天循环',
                      theme),
                  const SizedBox(width: 12),
                  _statChip(
                      Icons.restaurant,
                      '${_cycle.days.where((d) => d.mealTemplateId != null).length}天已分配',
                      theme),
                  const SizedBox(width: 12),
                  _statChip(
                      Icons.bedtime,
                      '${_cycle.days.where((d) => d.isRestDay).length}休息日',
                      theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text('循环日编辑',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('长按拖拽排序',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('点击修改标签/休息日 · 右侧选择配餐模板',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 8),

          // Reorderable day list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cycle.days.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
            itemBuilder: (context, index) {
              final day = _cycle.days[index];
              final templateName = day.mealTemplateId != null
                  ? widget.templates
                      .where((t) => t.id == day.mealTemplateId)
                      .firstOrNull
                      ?.name
                  : null;

              return Card(
                key: ValueKey('day_${day.dayIndex}_${day.mealTemplateId}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_handle, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: day.isRestDay
                            ? Colors.orange.withValues(alpha: 0.15)
                            : theme.colorScheme.primaryContainer,
                        child: Text('${day.dayIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: day.isRestDay
                                  ? Colors.orange
                                  : theme.colorScheme.primary,
                            )),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(day.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (day.isRestDay) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('休',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    templateName ?? '未分配配餐',
                    style: TextStyle(
                      color: templateName != null
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (day.mealTemplateId != null)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _cycle = _cycle.copyWith(
                                  days: _cycle.days.map((d) {
                                if (d.dayIndex == day.dayIndex)
                                  return d.copyWith(mealTemplateId: null);
                                return d;
                              }).toList());
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.edit_note,
                            size: 22, color: Colors.grey[500]),
                        onPressed: () => _editDay(context, day),
                        tooltip: '编辑日标签',
                      ),
                      IconButton(
                        icon: Icon(Icons.restaurant_menu,
                            size: 20,
                            color: day.mealTemplateId != null
                                ? theme.colorScheme.primary
                                : Colors.grey),
                        onPressed: () => _pickTemplate(context, day),
                        tooltip: '分配配餐',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Card(
            color: Colors.orange.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🍳 点击标签或休息日标记可修改\n🔄 长按左侧 ⋮⋮ 拖拽调整天数顺序',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
