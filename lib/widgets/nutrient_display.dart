import 'package:flutter/material.dart';

/// 三栏营养目标显示组件（蛋白质 / 碳水 / 卡路里）
class NutrientColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const NutrientColumn({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color;
    return Expanded(
      child: Column(children: [
        Icon(icon, color: effectiveColor.withValues(alpha: 0.7), size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: effectiveColor)),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: effectiveColor.withValues(alpha: 0.7))),
      ]),
    );
  }
}

/// 双栏营养对比显示（实际值 vs 目标值）
class NutrientComparisonRow extends StatelessWidget {
  final double actualProtein;
  final double actualCarbs;
  final double targetProtein;
  final double targetCarbs;

  const NutrientComparisonRow({
    super.key,
    required this.actualProtein,
    required this.actualCarbs,
    required this.targetProtein,
    required this.targetCarbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _NutrientBox(
          value: '${actualProtein.toStringAsFixed(1)}g',
          subtitle: '蛋白质 · 目标 ${targetProtein.toStringAsFixed(1)}g',
          color: Colors.orange,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _NutrientBox(
          value: '${actualCarbs.toStringAsFixed(1)}g',
          subtitle: '碳水 · 目标 ${targetCarbs.toStringAsFixed(1)}g',
          color: Colors.green,
        ),
      ),
    ]);
  }
}

class _NutrientBox extends StatelessWidget {
  final String value;
  final String subtitle;
  final Color color;

  const _NutrientBox({
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}
