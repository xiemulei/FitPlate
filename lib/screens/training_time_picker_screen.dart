import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/meal_plan_template.dart';
import '../data/meal_distribution.dart';
import '../services/storage_service.dart';

/// 选择器返回类型：预设方案返回 trainingTime，自定义方案返回 templateId
typedef MealPlanSelection = ({TrainingTime? trainingTime, String? templateId});

/// 训练时间配餐方案浏览与选择（含自定义方案）
class TrainingTimePickerScreen extends StatefulWidget {
  final UserProfile? profile;
  final TrainingTime? current;
  final String? currentTemplateId;

  const TrainingTimePickerScreen({
    super.key,
    this.profile,
    this.current,
    this.currentTemplateId,
  });

  @override
  State<TrainingTimePickerScreen> createState() =>
      _TrainingTimePickerScreenState();
}

class _TrainingTimePickerScreenState extends State<TrainingTimePickerScreen> {
  List<MealPlanTemplate> _customTemplates = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCustomTemplates();
  }

  Future<void> _loadCustomTemplates() async {
    final templates = await StorageService.loadMealPlanTemplates();
    if (mounted) {
      setState(() {
        _customTemplates = templates;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择配餐方案'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('根据你训练的时间段，选择对应的配餐方案',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 4),
          Text('每餐的碳水/蛋白质比例由方案内置，自动按你的体重和目标计算',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 16),
          ...MealDistributions.all.map(
              (d) => _buildPresetCard(context, d, theme)),
          if (_loaded && _customTemplates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.bookmark, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('我的方案',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ),
            ..._customTemplates.map(
                (t) => _buildCustomCard(context, t, theme)),
          ],
        ],
      ),
    );
  }

  // ── 预设方案卡片 ──
  Widget _buildPresetCard(
      BuildContext context, MealDistribution dist, ThemeData theme) {
    final isSelected = widget.current == dist.trainingTime &&
        widget.currentTemplateId == null;
    final label = dist.trainingTime.label;
    final icon = dist.trainingTime.icon;
    final desc = dist.trainingTime.dietDescription;

    // 计算实际克数（如果 profile 可用）
    final double? dailyCarbs = widget.profile?.dailyCarbs;
    final double? dailyRestCarbs = widget.profile?.dailyRestCarbs;
    final double? dailyProtein = widget.profile?.dailyProtein;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 头 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('当前',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary)),
                  ),
              ],
            ),
          ),

          // ── 训练日配餐 ──
          _mealSection('🏋️ 训练日配餐', dist.trainingDayMeals,
              dailyCarbs, dailyProtein, Colors.orange),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // ── 休息日配餐 ──
          _mealSection('😴 休息日配餐', dist.restDayMeals,
              dailyRestCarbs, dailyProtein, Colors.blue),

          // ── 选择按钮 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context,
                    (trainingTime: dist.trainingTime, templateId: null)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSelected
                      ? theme.colorScheme.primary
                      : null,
                ),
                child: Text(isSelected ? '使用此方案（当前）' : '使用此方案'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 自定义方案卡片 ──
  Widget _buildCustomCard(
      BuildContext context, MealPlanTemplate template, ThemeData theme) {
    final isSelected = widget.currentTemplateId == template.id;

    final double? dailyCarbs = widget.profile?.dailyCarbs;
    final double? dailyRestCarbs = widget.profile?.dailyRestCarbs;
    final double? dailyProtein = widget.profile?.dailyProtein;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 头 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('自定义方案 · ${template.trainingMeals.length}餐/${template.restMeals.length}餐',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('当前',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary)),
                  ),
              ],
            ),
          ),

          // ── 训练日配餐 ──
          _slotSection('🏋️ 训练日配餐', template.trainingMeals,
              dailyCarbs, dailyProtein, Colors.orange),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // ── 休息日配餐 ──
          _slotSection('😴 休息日配餐', template.restMeals,
              dailyRestCarbs, dailyProtein, Colors.blue),

          // ── 选择按钮 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context,
                    (trainingTime: null, templateId: template.id)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSelected
                      ? theme.colorScheme.primary
                      : null,
                ),
                child: Text(isSelected ? '使用此方案（当前）' : '使用此方案'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 预设方案餐次预览（MealPortion） ──
  Widget _mealSection(String title, List<MealPortion> meals,
      double? dailyCarbs, double? dailyProtein, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: accent)),
          const SizedBox(height: 6),
          ...meals.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final carbG = dailyCarbs != null
                ? (dailyCarbs * m.carbRatio).round()
                : null;
            final proteinG = dailyProtein != null
                ? (dailyProtein * m.proteinRatio).round()
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500])),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(m.name.replaceAll(RegExp(r'[①②③④⑤]'), ''),
                        style: const TextStyle(fontSize: 13)),
                  ),
                  // 比例
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '碳水 ${(m.carbRatio * 100).round()}%',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '蛋白 ${(m.proteinRatio * 100).round()}%',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800]),
                    ),
                  ),
                  if (carbG != null && proteinG != null) ...[
                    const Spacer(),
                    Text(
                      '≈ ${carbG}g碳/${proteinG}g蛋',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 自定义方案餐次预览（MealSlotDef） ──
  Widget _slotSection(String title, List<MealSlotDef> meals,
      double? dailyCarbs, double? dailyProtein, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: accent)),
          const SizedBox(height: 6),
          ...meals.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final carbG = dailyCarbs != null
                ? (dailyCarbs * m.carbRatio).round()
                : null;
            final proteinG = dailyProtein != null
                ? (dailyProtein * m.proteinRatio).round()
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500])),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(m.name.replaceAll(RegExp(r'[①②③④⑤]'), ''),
                        style: const TextStyle(fontSize: 13)),
                  ),
                  // 比例
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '碳水 ${(m.carbRatio * 100).round()}%',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '蛋白 ${(m.proteinRatio * 100).round()}%',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800]),
                    ),
                  ),
                  if (carbG != null && proteinG != null) ...[
                    const Spacer(),
                    Text(
                      '≈ ${carbG}g碳/${proteinG}g蛋',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
