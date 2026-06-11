import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/cycle.dart';

class CycleScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final ValueChanged<List<TrainingCycle>> onCyclesChanged;

  const CycleScreen({
    super.key,
    required this.cycles,
    required this.templates,
    required this.onCyclesChanged,
  });

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  void _createCycle() {
    final nameCtrl = TextEditingController();
    final lengthCtrl = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建新循环'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '循环名称',
                hintText: '如：三分化训练',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lengthCtrl,
              decoration: const InputDecoration(
                labelText: '循环天数',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_day),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [3, 4, 5, 6, 7].map((n) => ActionChip(
                label: Text('$n天'),
                onPressed: () {
                  lengthCtrl.text = n.toString();
                  setState(() {});
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            final name = nameCtrl.text.trim();
            final length = int.tryParse(lengthCtrl.text) ?? 4;
            if (name.isEmpty) return;

            final days = List.generate(length, (i) => CycleDay(
              dayIndex: i,
              label: i == length - 1 ? '休息日' : '训练日${i + 1}',
              isRestDay: i == length - 1,
            ));

            final cycle = TrainingCycle(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              cycleLength: length,
              days: days,
              startDate: DateTime.now().toIso8601String().split('T')[0],
              isActive: widget.cycles.isEmpty,
            );

            widget.onCyclesChanged([...widget.cycles, cycle]);
            Navigator.pop(ctx);
          }, child: const Text('创建')),
        ],
      ),
    );
  }

  void _editCycle(TrainingCycle cycle) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _CycleEditor(
        cycle: cycle,
        templates: widget.templates,
        onSave: (updated) {
          widget.onCyclesChanged(widget.cycles.map((c) => c.id == updated.id ? updated : c).toList());
        },
      ),
    ));
  }

  void _toggleActive(TrainingCycle cycle) {
    widget.onCyclesChanged(widget.cycles.map((c) {
      if (c.id == cycle.id) {
        return c.copyWith(
          startDate: DateTime.now().toIso8601String().split('T')[0],
          isActive: !c.isActive,
        );
      }
      return c.copyWith(isActive: false);
    }).toList());
  }

  void _copyCycle(TrainingCycle cycle) {
    final newCycle = TrainingCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${cycle.name} (副本)',
      cycleLength: cycle.cycleLength,
      days: cycle.days.map((d) => CycleDay(
        dayIndex: d.dayIndex,
        label: d.label,
        isRestDay: d.isRestDay,
        mealTemplateId: d.mealTemplateId,
      )).toList(),
      startDate: null,
      isActive: false,
    );
    widget.onCyclesChanged([...widget.cycles, newCycle]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('循环已复制'), duration: Duration(seconds: 2)),
    );
  }

  void _deleteCycle(TrainingCycle cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除循环'),
        content: Text('确定删除「${cycle.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onCyclesChanged(widget.cycles.where((c) => c.id != cycle.id).toList());
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _resetCycleDate(TrainingCycle cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置开始日期'),
        content: const Text('将循环的开始日期设为今天？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            widget.onCyclesChanged(widget.cycles.map((c) {
              if (c.id == cycle.id) {
                return c.copyWith(startDate: DateTime.now().toIso8601String().split('T')[0]);
              }
              return c;
            }).toList());
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('开始日期已重置为今天'), duration: Duration(seconds: 2)),
            );
          }, child: const Text('重置')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('训练循环', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            FilledButton.icon(
              onPressed: _createCycle,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.templates.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('提示: 先在「配餐」页面保存一些配餐模板，然后分配到循环的每一天',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
        const SizedBox(height: 4),
        if (widget.cycles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.loop, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('还没有循环', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('点击新建创建你的第一个训练循环',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...widget.cycles.map((cycle) => _CycleCard(
            cycle: cycle,
            templates: widget.templates,
            theme: theme,
            onTap: () => _editCycle(cycle),
            onToggle: () => _toggleActive(cycle),
            onCopy: () => _copyCycle(cycle),
            onResetDate: () => _resetCycleDate(cycle),
            onDelete: () => _deleteCycle(cycle),
          )),
      ],
    );
  }
}

class _CycleCard extends StatelessWidget {
  final TrainingCycle cycle;
  final List<MealTemplate> templates;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onResetDate;
  final VoidCallback onDelete;

  const _CycleCard({
    required this.cycle, required this.templates, required this.theme,
    required this.onTap, required this.onToggle, required this.onCopy,
    required this.onResetDate, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final todayIdx = cycle.todayIndex;
    final progress = cycle.progressPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cycle.isActive ? Icons.play_circle_fill : Icons.circle_outlined,
                        color: cycle.isActive ? Colors.green : Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cycle.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      if (cycle.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('激活中', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('${cycle.cycleLength}天循环',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      if (cycle.startDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.play_arrow, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('始于 ${cycle.startDate}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                      if (cycle.daysActive != null && cycle.daysActive! > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.loop, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${cycle.daysActive}天前',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Progress bar
          if (cycle.isActive && progress != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('循环进度', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Day indicators
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: cycle.days.asMap().entries.map((entry) {
                  final d = entry.value;
                  final isToday = d.dayIndex == (todayIdx ?? -1);
                  final hasTemplate = d.mealTemplateId != null &&
                      templates.any((t) => t.id == d.mealTemplateId);
                  Color bgColor;
                  if (isToday) {
                    bgColor = theme.colorScheme.primary;
                  } else if (d.isRestDay) {
                    bgColor = Colors.orange.withValues(alpha: 0.15);
                  } else if (hasTemplate) {
                    bgColor = theme.colorScheme.primaryContainer;
                  } else {
                    bgColor = Colors.grey.withValues(alpha: 0.06);
                  }
                  return Expanded(
                    child: Container(
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          d.label.length > 3 ? d.label.substring(0, 3) : d.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? theme.colorScheme.onPrimary
                                : d.isRestDay
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(cycle.isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(cycle.isActive ? '停用' : '激活', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                  label: Text('复制', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                if (cycle.startDate != null)
                  TextButton.icon(
                    onPressed: onResetDate,
                    icon: Icon(Icons.refresh, size: 16, color: Colors.grey[600]),
                    label: Text('重置', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('删除', style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editor ─────────────────────────────────────────────────────────────────

class _CycleEditor extends StatefulWidget {
  final TrainingCycle cycle;
  final List<MealTemplate> templates;
  final ValueChanged<TrainingCycle> onSave;

  const _CycleEditor({
    required this.cycle, required this.templates, required this.onSave,
  });

  @override
  State<_CycleEditor> createState() => _CycleEditorState();
}

class _CycleEditorState extends State<_CycleEditor> {
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () {
              setState(() {
                _cycle = _cycle.copyWith(days: _cycle.days.map((d) {
                  if (d.dayIndex == day.dayIndex) {
                    return CycleDay(
                      dayIndex: d.dayIndex,
                      label: labelCtrl.text.trim().isEmpty ? d.label : labelCtrl.text.trim(),
                      isRestDay: isRestDay,
                      mealTemplateId: d.mealTemplateId,
                    );
                  }
                  return d;
                }).toList());
              });
              Navigator.pop(ctx);
            }, child: const Text('确定')),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 16),
            if (widget.templates.isEmpty)
              const Center(child: Text('还没有配餐模板，先去配餐页面保存吧', style: TextStyle(color: Colors.grey)))
            else ...[
              RadioListTile<String?>(
                title: const Text('不分配'),
                value: null,
                groupValue: day.mealTemplateId,
                onChanged: (val) {
                  setState(() {
                    _cycle = _cycle.copyWith(days: _cycle.days.map((d) {
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
                subtitle: Text('目标 ${t.target.protein.toStringAsFixed(0)}P / ${t.target.carbs.toStringAsFixed(0)}C'),
                value: t.id,
                groupValue: day.mealTemplateId,
                onChanged: (val) {
                  setState(() {
                    _cycle = _cycle.copyWith(days: _cycle.days.map((d) {
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
      updated.insert(newIndex, CycleDay(
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
                  _statChip(Icons.calendar_view_day, '${_cycle.cycleLength}天循环', theme),
                  const SizedBox(width: 12),
                  _statChip(Icons.restaurant, '${_cycle.days.where((d) => d.mealTemplateId != null).length}天已分配', theme),
                  const SizedBox(width: 12),
                  _statChip(Icons.bedtime, '${_cycle.days.where((d) => d.isRestDay).length}休息日', theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text('循环日编辑', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('长按拖拽排序', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                  ? widget.templates.where((t) => t.id == day.mealTemplateId).firstOrNull?.name
                  : null;

              return Card(
                key: ValueKey('day_${day.dayIndex}_${day.mealTemplateId}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: day.isRestDay ? Colors.orange : theme.colorScheme.primary,
                          )),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(day.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (day.isRestDay) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('休', style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    templateName ?? '未分配配餐',
                    style: TextStyle(
                      color: templateName != null ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (day.mealTemplateId != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _cycle = _cycle.copyWith(days: _cycle.days.map((d) {
                                if (d.dayIndex == day.dayIndex) return d.copyWith(mealTemplateId: null);
                                return d;
                              }).toList());
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.edit_note, size: 22, color: Colors.grey[500]),
                        onPressed: () => _editDay(context, day),
                        tooltip: '编辑日标签',
                      ),
                      IconButton(
                        icon: Icon(Icons.restaurant_menu, size: 20,
                          color: day.mealTemplateId != null ? theme.colorScheme.primary : Colors.grey),
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
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
