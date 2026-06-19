import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/user_profile.dart';
import '../models/cycle.dart';
import 'cycle_editor_screen.dart';

class CycleScreen extends StatefulWidget {
  final List<TrainingCycle> cycles;
  final List<MealTemplate> templates;
  final UserProfile? profile;
  final ValueChanged<List<TrainingCycle>> onCyclesChanged;

  const CycleScreen({
    super.key,
    required this.cycles,
    required this.templates,
    this.profile,
    required this.onCyclesChanged,
  });

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  void _createCycle() {
    final nameCtrl = TextEditingController();
    final lengthCtrl = TextEditingController(text: '4');
    String? selectedPreset;
    // 训练时间方案：默认取 profile 的，否则用午饭后练
    TrainingTime selectedTime =
        widget.profile?.trainingTime ?? TrainingTime.afterLunch;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('创建新循环'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                Text('快速预设',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('🏋️ 三分化（练三休一）'),
                      onPressed: () {
                        nameCtrl.text = '三分化训练';
                        lengthCtrl.text = '4';
                        setDialogState(() => selectedPreset = '三分化');
                      },
                    ),
                    ActionChip(
                      label: const Text('🏋️ 四分化（练二休一循环）'),
                      onPressed: () {
                        nameCtrl.text = '四分化训练';
                        lengthCtrl.text = '3';
                        setDialogState(() => selectedPreset = '四分化');
                      },
                    ),
                    ActionChip(
                      label: const Text('自定义'),
                      onPressed: () {
                        setDialogState(() => selectedPreset = null);
                      },
                    ),
                  ],
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
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final length = int.tryParse(lengthCtrl.text) ?? 4;
                  if (name.isEmpty) return;

                  List<CycleDay> days;
                  if (selectedPreset == '三分化') {
                    days = [
                      CycleDay(dayIndex: 0, label: '胸/推', isRestDay: false),
                      CycleDay(dayIndex: 1, label: '背/拉', isRestDay: false),
                      CycleDay(dayIndex: 2, label: '腿', isRestDay: false),
                      CycleDay(dayIndex: 3, label: '休息日', isRestDay: true),
                    ];
                  } else if (selectedPreset == '四分化') {
                    days = [
                      CycleDay(dayIndex: 0, label: '上肢推', isRestDay: false),
                      CycleDay(dayIndex: 1, label: '上肢拉', isRestDay: false),
                      CycleDay(dayIndex: 2, label: '休息日', isRestDay: true),
                    ];
                  } else {
                    days = List.generate(
                        length,
                        (i) => CycleDay(
                              dayIndex: i,
                              label: i == length - 1 ? '休息日' : '训练日${i + 1}',
                              isRestDay: i == length - 1,
                            ));
                  }

                  final cycle = TrainingCycle(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    cycleLength: days.length,
                    days: days,
                    startDate: DateTime.now().toIso8601String().split('T')[0],
                    isActive: widget.cycles.isEmpty,
                    trainingTime: selectedTime,
                  );

                  widget.onCyclesChanged([...widget.cycles, cycle]);
                  Navigator.pop(ctx);
                },
                child: const Text('创建')),
          ],
        ),
      ),
    );
  }

  void _editCycle(TrainingCycle cycle) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CycleEditorScreen(
            cycle: cycle,
            profile: widget.profile,
            onSave: (updated) {
              widget.onCyclesChanged(widget.cycles
                  .map((c) => c.id == updated.id ? updated : c)
                  .toList());
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
      days: cycle.days
          .map((d) => CycleDay(
                dayIndex: d.dayIndex,
                label: d.label,
                isRestDay: d.isRestDay,
                mealTemplateId: d.mealTemplateId,
              ))
          .toList(),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onCyclesChanged(
                  widget.cycles.where((c) => c.id != cycle.id).toList());
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () {
                widget.onCyclesChanged(widget.cycles.map((c) {
                  if (c.id == cycle.id) {
                    return c.copyWith(
                        startDate:
                            DateTime.now().toIso8601String().split('T')[0]);
                  }
                  return c;
                }).toList());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('开始日期已重置为今天'),
                      duration: Duration(seconds: 2)),
                );
              },
              child: const Text('重置')),
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
            Text('训练循环',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
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
                  Text('还没有循环',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey)),
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
                profile: widget.profile,
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
  final UserProfile? profile;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onResetDate;
  final VoidCallback onDelete;

  const _CycleCard({
    required this.cycle,
    required this.templates,
    required this.profile,
    required this.theme,
    required this.onTap,
    required this.onToggle,
    required this.onCopy,
    required this.onResetDate,
    required this.onDelete,
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
                      Icon(
                          cycle.isActive
                              ? Icons.play_circle_fill
                              : Icons.circle_outlined,
                          color: cycle.isActive ? Colors.green : Colors.grey,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(cycle.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16))),
                      if (cycle.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('激活中',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('${cycle.cycleLength}天循环',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                      if (cycle.startDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.play_arrow,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('始于 ${cycle.startDate}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ],
                      if (cycle.daysActive != null &&
                          cycle.daysActive! > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.loop, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${cycle.daysActive}天前',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
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
                      Text('循环进度',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[400])),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

          // Nutrition target summary
          if (profile != null) _buildNutritionRow(),

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
                          d.label.length > 3
                              ? d.label.substring(0, 3)
                              : d.label,
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
                  icon: Icon(cycle.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16),
                  label: Text(cycle.isActive ? '停用' : '激活',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                  label: Text('复制',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                if (cycle.startDate != null)
                  TextButton.icon(
                    onPressed: onResetDate,
                    icon:
                        Icon(Icons.refresh, size: 16, color: Colors.grey[600]),
                    label: Text('重置',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  label: const Text('删除',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow() {
    final p = profile!;
    final trainCarbs = (p.weight * p.carbsPerKg).round();
    final restCarbs = (p.weight * p.restCarbsPerKg).round();
    final protein = (p.weight * p.proteinPerKg).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('🏋️ C${trainCarbs}g P${protein}g',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 10),
          Text('😴 C${restCarbs}g P${protein}g',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

