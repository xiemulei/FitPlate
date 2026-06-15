import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../data/meal_distribution.dart';

/// 训练时间配餐方案浏览与选择
class TrainingTimePickerScreen extends StatelessWidget {
  final UserProfile? profile;
  final TrainingTime? current;

  const TrainingTimePickerScreen({
    super.key,
    this.profile,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择训练时间方案'),
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
              (d) => _buildCard(context, d, theme)),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, MealDistribution dist, ThemeData theme) {
    final isSelected = current == dist.trainingTime;
    final label = dist.trainingTime.label;
    final icon = dist.trainingTime.icon;
    final desc = dist.trainingTime.dietDescription;

    // 计算实际克数（如果 profile 可用）
    final double? dailyCarbs = profile != null ? profile!.dailyCarbs : null;
    final double? dailyProtein =
        profile != null ? profile!.dailyProtein : null;

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
              dailyCarbs, dailyProtein, Colors.blue),

          // ── 选择按钮 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, dist.trainingTime),
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
}
