import 'package:flutter/material.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../models/meal_plan_template.dart';
import '../data/meal_distribution.dart';
import '../services/storage_service.dart';
import 'training_time_picker_screen.dart';

class CycleEditorScreen extends StatefulWidget {
  final TrainingCycle cycle;
  final UserProfile? profile;
  final ValueChanged<TrainingCycle> onSave;

  const CycleEditorScreen({
    super.key,
    required this.cycle,
    this.profile,
    required this.onSave,
  });

  @override
  State<CycleEditorScreen> createState() => _CycleEditorScreenState();
}

class _CycleEditorScreenState extends State<CycleEditorScreen> {
  late TrainingCycle _cycle;
  late TextEditingController _nameCtrl;
  MealPlanTemplate? _customTemplate;

  @override
  void initState() {
    super.initState();
    _cycle = widget.cycle;
    _nameCtrl = TextEditingController(text: _cycle.name);
    _loadCustomTemplate();
  }

  Future<void> _loadCustomTemplate() async {
    if (_cycle.mealPlanTemplateId == null) return;
    final templates = await StorageService.loadMealPlanTemplates();
    final match = templates
        .where((t) => t.id == _cycle.mealPlanTemplateId)
        .firstOrNull;
    if (mounted && match != null) {
      setState(() {
        _customTemplate = match;
      });
    }
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
                activeTrackColor: Colors.orange.withValues(alpha: 0.3),
                activeThumbColor: Colors.orange,
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

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
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
                      Icons.bedtime,
                      '${_cycle.days.where((d) => d.isRestDay).length}休息日',
                      theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 配餐方案 ──
          _buildTrainingTimeCard(theme),
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
          Text('点击修改标签/休息日',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 8),

          // Reorderable day list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cycle.days.length,
            onReorderItem: _onReorderItem,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
            itemBuilder: (context, index) {
              final day = _cycle.days[index];

              return Card(
                key: ValueKey('day_$index'),
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
                    day.isRestDay ? '休息日 · 使用休息日配餐' : '训练日 · 使用训练日配餐',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note,
                            size: 22, color: Colors.grey[500]),
                        onPressed: () => _editDay(context, day),
                        tooltip: '编辑日标签',
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

  // ── 配餐方案卡 ──
  Widget _buildTrainingTimeCard(ThemeData theme) {
    // 优先检查自定义方案
    if (_cycle.mealPlanTemplateId != null) {
      return _buildCustomTemplateCard(theme);
    }

    final effectiveTime =
        _cycle.trainingTime ?? widget.profile?.trainingTime;
    if (effectiveTime == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.restaurant_menu,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('未设置配餐方案',
                    style: TextStyle(fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: _changeTrainingTime,
              child: const Text('设置', style: TextStyle(fontSize: 13)),
            ),
          ]),
        ),
      );
    }

    final dist = MealDistributions.forTrainingTime(effectiveTime);
    if (dist == null) return const SizedBox.shrink();

    final profile = widget.profile;
    final dailyCarbs =
        profile != null ? profile.weight * profile.carbsPerKg : null;
    final dailyRestCarbs =
        profile != null ? profile.weight * profile.restCarbsPerKg : null;
    final dailyProtein =
        profile != null ? profile.weight * profile.proteinPerKg : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Text(effectiveTime.icon,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('配餐方案: ${effectiveTime.label}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                TextButton(
                  onPressed: _changeTrainingTime,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('换方案',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          // 训练日
          _mealPreviewGroup('🏋️ 训练日配餐', dist.trainingDayMeals,
              dailyCarbs, dailyProtein, Colors.orange),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // 休息日
          _mealPreviewGroup('😴 休息日配餐', dist.restDayMeals,
              dailyRestCarbs, dailyProtein, Colors.blue),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _mealPreviewGroup(String title, List<MealPortion> meals,
      double? dailyCarbs, double? dailyProtein, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: accent)),
          const SizedBox(height: 4),
          ...meals.asMap().entries.map((e) {
            final m = e.value;
            final carbG = dailyCarbs != null
                ? (dailyCarbs * m.carbRatio).round()
                : null;
            final proteinG = dailyProtein != null
                ? (dailyProtein * m.proteinRatio).round()
                : null;
            final name =
                m.name.replaceAll(RegExp(r'[①②③④⑤]'), '').trim();

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(name,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Spacer(),
                  if (carbG != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('C ${carbG}g',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800])),
                    ),
                  const SizedBox(width: 4),
                  if (proteinG != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('P ${proteinG}g',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800])),
                    ),
                  if (carbG == null)
                    Text(
                        '碳水${(m.carbRatio * 100).round()}% 蛋白${(m.proteinRatio * 100).round()}%',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 自定义方案预览卡 ──
  Widget _buildCustomTemplateCard(ThemeData theme) {
    final profile = widget.profile;
    final dailyCarbs =
        profile != null ? profile.weight * profile.carbsPerKg : null;
    final dailyRestCarbs =
        profile != null ? profile.weight * profile.restCarbsPerKg : null;
    final dailyProtein =
        profile != null ? profile.weight * profile.proteinPerKg : null;

    // 模板尚未加载完成
    if (_customTemplate == null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('自定义方案加载中…',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  TextButton(
                    onPressed: _changeTrainingTime,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('换方案',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    final template = _customTemplate!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('配餐方案: ${template.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                TextButton(
                  onPressed: _changeTrainingTime,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('换方案',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          // 训练日
          _slotPreviewGroup('🏋️ 训练日配餐', template.trainingMeals,
              dailyCarbs, dailyProtein, Colors.orange),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // 休息日
          _slotPreviewGroup('😴 休息日配餐', template.restMeals,
              dailyRestCarbs, dailyProtein, Colors.blue),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── 自定义方案餐次预览（MealSlotDef） ──
  Widget _slotPreviewGroup(String title, List<MealSlotDef> meals,
      double? dailyCarbs, double? dailyProtein, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: accent)),
          const SizedBox(height: 4),
          ...meals.asMap().entries.map((e) {
            final m = e.value;
            final carbG = dailyCarbs != null
                ? (dailyCarbs * m.carbRatio).round()
                : null;
            final proteinG = dailyProtein != null
                ? (dailyProtein * m.proteinRatio).round()
                : null;
            final name =
                m.name.replaceAll(RegExp(r'[①②③④⑤]'), '').trim();

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(name,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Spacer(),
                  if (carbG != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('C ${carbG}g',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800])),
                    ),
                  const SizedBox(width: 4),
                  if (proteinG != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('P ${proteinG}g',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800])),
                    ),
                  if (carbG == null)
                    Text(
                        '碳水${(m.carbRatio * 100).round()}% 蛋白${(m.proteinRatio * 100).round()}%',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _changeTrainingTime() async {
    final effectiveTime =
        _cycle.trainingTime ?? widget.profile?.trainingTime;
    final result = await Navigator.push<MealPlanSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingTimePickerScreen(
          profile: widget.profile,
          current: effectiveTime,
          currentTemplateId: _cycle.mealPlanTemplateId,
        ),
      ),
    );
    if (result == null) return;

    if (result.templateId != null) {
      // 选择了自定义方案
      setState(() {
        _cycle = _cycle.copyWith(
          mealPlanTemplateId: result.templateId,
        );
        // 直接置空 trainingTime（copyWith 用 ?? 无法清空）
        _cycle.trainingTime = null;
      });
      _loadCustomTemplate();
    } else if (result.trainingTime != null &&
        result.trainingTime != _cycle.trainingTime) {
      // 选择了预设方案
      setState(() {
        _cycle = _cycle.copyWith(
          trainingTime: result.trainingTime,
        );
        // 直接置空 mealPlanTemplateId（copyWith 用 ?? 无法清空）
        _cycle.mealPlanTemplateId = null;
        _customTemplate = null;
      });
    }
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
