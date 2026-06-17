import 'package:flutter/material.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';
import '../models/food.dart';

/// 饮食历史记录 — 查看过去每天吃了什么
class HistoryScreen extends StatefulWidget {
  final List<Food> foods;

  const HistoryScreen({super.key, required this.foods});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailyFoodLog> _logs = [];
  bool _loading = true;
  String? _selectedDate;
  DailyFoodLog? _selectedLog;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await StorageService.loadDailyLogs();
    logs.sort((a, b) => b.date.compareTo(a.date)); // 最新的在前
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
        if (_logs.isNotEmpty) {
          _selectedDate = _logs.first.date;
          _selectedLog = _logs.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text('还没有饮食记录',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('在"今天"页面选完食物后，记录会自动保存',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── 日期选择条 ──
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _logs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (ctx, i) {
              final log = _logs[i];
              final selected = log.date == _selectedDate;
              return _DateChip(
                date: log.date,
                label: log.cycleName,
                isRestDay: log.isRestDay,
                selected: selected,
                onTap: () => setState(() {
                  _selectedDate = log.date;
                  _selectedLog = log;
                }),
              );
            },
          ),
        ),
        const Divider(height: 1),

        // ── 选中天的详情 ──
        if (_selectedLog != null)
          Expanded(
            child: _HistoryDetail(log: _selectedLog!, foods: widget.foods),
          ),
      ],
    );
  }
}

/// 日期芯片
class _DateChip extends StatelessWidget {
  final String date;
  final String label;
  final bool isRestDay;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.label,
    required this.isRestDay,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 格式化显示：06-17 周三
    final parts = date.split('-');
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    final dateObj = DateTime.tryParse(date);
    final weekday = dateObj != null
        ? ['一', '二', '三', '四', '五', '六', '日'][dateObj.weekday - 1]
        : '';
    final isToday = date == DailyFoodLog.todayDate();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : isRestDay
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(weekday,
                    style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.8)
                            : Colors.grey[500])),
                if (isToday) ...[
                  const SizedBox(width: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 某天的详细饮食记录
class _HistoryDetail extends StatelessWidget {
  final DailyFoodLog log;
  final List<Food> foods;

  const _HistoryDetail({required this.log, required this.foods});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCarbs =
        log.meals.fold(0, (s, e) => s + e.targetCarbsG);
    final totalProtein =
        log.meals.fold(0, (s, e) => s + e.targetProteinG);

    double actualCarbs = 0, actualProtein = 0;
    for (final meal in log.meals) {
      for (final sv in meal.servings) {
        actualCarbs += sv.carbsPer100G / 100 * sv.grams;
        actualProtein += sv.proteinPer100G / 100 * sv.grams;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 当天头部 ──
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: log.isRestDay
                  ? Colors.grey.withValues(alpha: 0.2)
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                log.isRestDay ? Icons.bedtime : Icons.fitness_center,
                size: 20,
                color: log.isRestDay
                    ? Colors.grey
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.isRestDay ? '休息日' : '训练日',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('D${log.cycleDayIndex + 1} · ${log.cycleName}',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('碳水 ${actualCarbs.round()}/${totalCarbs}g',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800])),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('蛋白 ${actualProtein.round()}/${totalProtein}g',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800])),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── 各餐 ──
        ...log.meals.asMap().entries.map((e) =>
            _buildMealCard(theme, e.key, e.value)),

        const SizedBox(height: 16),

        // ── 当日合计 ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('碳水', actualCarbs, totalCarbs.toDouble(),
                    Colors.orange),
                _stat('蛋白质', actualProtein, totalProtein.toDouble(),
                    Colors.green),
                _statItem('食物种类',
                    '${log.meals.fold(0, (s, e) => s + e.servings.length)}种'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, double actual, double target, Color c) {
    return Column(children: [
      Text('${actual.round()} / ${target.round()}',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: actual >= target ? Colors.green : c)),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
    ]);
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
    ]);
  }

  Widget _buildMealCard(
      ThemeData theme, int index, MealFoodLog meal) {
    IconData mealIcon(String label) {
      final l = label.toLowerCase();
      if (l.contains('早')) return Icons.wb_sunny;
      if (l.contains('练') || l.contains('训')) {
        return Icons.fitness_center;
      }
      if (l.contains('午')) return Icons.restaurant;
      if (l.contains('晚')) return Icons.nights_stay;
      if (l.contains('加')) return Icons.cookie;
      return Icons.restaurant_menu;
    }

    double actualCarbs = 0, actualProtein = 0;
    for (final sv in meal.servings) {
      actualCarbs += sv.carbsPer100G / 100 * sv.grams;
      actualProtein += sv.proteinPer100G / 100 * sv.grams;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(mealIcon(meal.mealLabel), size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(meal.mealLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text('C ${actualCarbs.round()}/${meal.targetCarbsG}g',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text('P ${actualProtein.round()}/${meal.targetProteinG}g',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500)),
            ]),
            if (meal.servings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...meal.servings.map((sv) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(sv.foodName,
                            style: const TextStyle(fontSize: 13)),
                        const Spacer(),
                        Text('${sv.grams.round()}g',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600])),
                        const SizedBox(width: 8),
                        Text(
                          '碳${(sv.carbsPer100G / 100 * sv.grams).round()}g',
                          style: TextStyle(
                              fontSize: 10, color: Colors.orange[400]),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '蛋${(sv.proteinPer100G / 100 * sv.grams).round()}g',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green[400]),
                        ),
                      ],
                    ),
                  )),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('未记录',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[400])),
              ),
          ],
        ),
      ),
    );
  }
}
