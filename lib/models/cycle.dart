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

class TrainingCycle {
  String id;
  String name;
  int cycleLength;
  List<CycleDay> days;
  String? startDate;
  bool isActive;
  TrainingTime? trainingTime; // 覆盖 UserProfile 中的训练时间设置

  TrainingCycle({
    required this.id,
    required this.name,
    required this.cycleLength,
    required this.days,
    this.startDate,
    this.isActive = false,
    this.trainingTime,
  });

  TrainingCycle copyWith({
    String? id,
    String? name,
    int? cycleLength,
    List<CycleDay>? days,
    String? startDate,
    bool? isActive,
    TrainingTime? trainingTime,
  }) {
    return TrainingCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      cycleLength: cycleLength ?? this.cycleLength,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      trainingTime: trainingTime ?? this.trainingTime,
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

  CycleDay? get todayDay {
    final idx = todayIndex;
    if (idx == null || idx >= days.length) return null;
    return days[idx];
  }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cycleLength': cycleLength,
        'days': days.map((d) => d.toJson()).toList(),
        'startDate': startDate,
        'isActive': isActive,
        'trainingTime': trainingTime?.name,
      };

  factory TrainingCycle.fromJson(Map<String, dynamic> j) => TrainingCycle(
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
      );
}
