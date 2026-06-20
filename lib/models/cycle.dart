import '../models/user_profile.dart';

/// 训练循环模型
class CycleDay {
  int dayIndex;
  String label;
  bool isRestDay;
  String? mealTemplateId;

  CycleDay({
    required this.dayIndex,
    required this.label,
    this.isRestDay = false,
    this.mealTemplateId,
  });

  CycleDay copyWith({
    int? dayIndex,
    String? label,
    bool? isRestDay,
    String? mealTemplateId,
  }) {
    return CycleDay(
      dayIndex: dayIndex ?? this.dayIndex,
      label: label ?? this.label,
      isRestDay: isRestDay ?? this.isRestDay,
      mealTemplateId: mealTemplateId ?? this.mealTemplateId,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'label': label,
        'isRestDay': isRestDay,
        'mealTemplateId': mealTemplateId,
      };

  factory CycleDay.fromJson(Map<String, dynamic> j) => CycleDay(
        dayIndex: j['dayIndex'],
        label: j['label'],
        isRestDay: j['isRestDay'] ?? false,
        mealTemplateId: j['mealTemplateId'],
      );
}

/// 单日覆盖类型
enum DayOverrideType { rest }

class TrainingCycle {
  String id;
  String name;
  int cycleLength;
  List<CycleDay> days;
  String? startDate;
  bool isActive;
  TrainingTime? trainingTime; // 覆盖 UserProfile 中的训练时间设置
  Map<int, DayOverrideType> overrides; // dayIndex → 覆盖类型

  TrainingCycle({
    required this.id,
    required this.name,
    required this.cycleLength,
    required this.days,
    this.startDate,
    this.isActive = false,
    this.trainingTime,
    Map<int, DayOverrideType>? overrides,
  }) : overrides = overrides ?? {};

  TrainingCycle copyWith({
    String? id,
    String? name,
    int? cycleLength,
    List<CycleDay>? days,
    String? startDate,
    bool? isActive,
    TrainingTime? trainingTime,
    Map<int, DayOverrideType>? overrides,
  }) {
    return TrainingCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      cycleLength: cycleLength ?? this.cycleLength,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      trainingTime: trainingTime ?? this.trainingTime,
      overrides: overrides ?? Map<int, DayOverrideType>.from(this.overrides),
    );
  }

  int? get todayIndex {
    if (startDate == null) return null;
    final start = DateTime.tryParse(startDate!);
    if (start == null) return null;
    final now = DateTime.now();
    final diff = now.difference(start).inDays;
    if (diff < 0) return null;
    return diff % cycleLength;
  }

  /// 今天的日类型（考虑临时覆盖）
  CycleDay? get todayDay {
    final idx = todayIndex;
    if (idx == null || idx >= days.length) return null;
    final day = days[idx];
    final ov = overrides[idx];
    if (ov == DayOverrideType.rest) {
      return day.copyWith(isRestDay: true, label: '休息');
    }
    return day;
  }

  /// 今天是否被覆盖为休息
  bool get isTodayOverridden =>
      todayIndex != null && overrides.containsKey(todayIndex!);

  String? get todayTemplateId => todayDay?.mealTemplateId;

  int? get daysActive {
    if (startDate == null) return null;
    final start = DateTime.tryParse(startDate!);
    if (start == null) return null;
    return DateTime.now().difference(start).inDays;
  }

  double? get progressPercent {
    final idx = todayIndex;
    if (idx == null) return null;
    return (idx + 1) / cycleLength;
  }

  /// 清理所有覆盖（每轮循环结束后调用）
  void clearOverrides() {
    overrides.clear();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cycleLength': cycleLength,
        'days': days.map((d) => d.toJson()).toList(),
        'startDate': startDate,
        'isActive': isActive,
        'trainingTime': trainingTime?.name,
        if (overrides.isNotEmpty)
          'overrides': overrides.map((k, v) => MapEntry(k.toString(), v.name)),
      };

  factory TrainingCycle.fromJson(Map<String, dynamic> j) {
    final rawOverrides = j['overrides'] as Map<String, dynamic>?;
    return TrainingCycle(
      id: j['id'],
      name: j['name'],
      cycleLength: j['cycleLength'],
      days: (j['days'] as List).map((d) => CycleDay.fromJson(d)).toList(),
      startDate: j['startDate'],
      isActive: j['isActive'] ?? false,
      trainingTime: j['trainingTime'] != null
          ? TrainingTime.values.firstWhere(
              (t) => t.name == j['trainingTime'],
              orElse: () => TrainingTime.afterLunch,
            )
          : null,
      overrides: rawOverrides != null
          ? rawOverrides.map((k, v) =>
              MapEntry(int.parse(k), DayOverrideType.values.firstWhere(
                (t) => t.name == v,
                orElse: () => DayOverrideType.rest,
              )))
          : {},
    );
  }
}
