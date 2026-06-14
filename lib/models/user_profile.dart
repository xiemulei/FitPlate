enum Gender { male, female }

enum FitnessGoal { fatLoss, muscleGain }

enum TrainingTime {
  afterEarlyBreakfast,
  afterLateBreakfast,
  beforeLunch,
  afterLunch,
  afterDinner,
  night,
}

extension TrainingTimeX on TrainingTime {
  String get label {
    switch (this) {
      case TrainingTime.afterEarlyBreakfast:
        return '早饭后练（早起版）';
      case TrainingTime.afterLateBreakfast:
        return '早饭后练（晚起版）';
      case TrainingTime.beforeLunch:
        return '午饭前练';
      case TrainingTime.afterLunch:
        return '午饭后练';
      case TrainingTime.afterDinner:
        return '晚饭后练';
      case TrainingTime.night:
        return '夜里练';
    }
  }

  String get icon {
    switch (this) {
      case TrainingTime.afterEarlyBreakfast:
        return '🔆';
      case TrainingTime.afterLateBreakfast:
        return '🌤️';
      case TrainingTime.beforeLunch:
        return '☀️';
      case TrainingTime.afterLunch:
        return '🌆';
      case TrainingTime.afterDinner:
        return '🌇';
      case TrainingTime.night:
        return '🌙';
    }
  }

  String get dietDescription {
    switch (this) {
      case TrainingTime.afterEarlyBreakfast:
        return '起床→早餐→训练，练后补蛋白';
      case TrainingTime.afterLateBreakfast:
        return '晚起吃早餐，午餐前练完，午餐补碳蛋';
      case TrainingTime.beforeLunch:
        return '空腹或练前加餐→训练→午餐补碳蛋';
      case TrainingTime.afterLunch:
        return '午餐消化→训练→晚餐补充';
      case TrainingTime.afterDinner:
        return '晚餐→训练→练后加蛋白';
      case TrainingTime.night:
        return '晚餐→晚练→睡前补充';
    }
  }
}

/// 每千克摄入参考数据行
class MacroReferenceRow {
  final String intensity;
  final String proteinRange;
  final String carbRange;
  final String note;

  const MacroReferenceRow(
      this.intensity, this.proteinRange, this.carbRange, this.note);

  static const fatLossTable = [
    MacroReferenceRow('保守', '1.6–1.8', '1.5–2.0', '适合刚开始减脂，训练强度中等'),
    MacroReferenceRow('中等', '1.8–2.2', '1.0–1.5', '平衡碳蛋分配，推荐大多数人群'),
    MacroReferenceRow('激进', '2.2–2.6', '0.5–1.0', '快速减脂，注意训练表现可能下降'),
  ];

  static const muscleGainTable = [
    MacroReferenceRow('保守', '1.4–1.6', '3.0–4.0', '干净增肌，适合易囤脂人群'),
    MacroReferenceRow('中等', '1.6–1.8', '4.0–5.0', '均衡增肌，推荐大多数人群'),
    MacroReferenceRow('激进', '1.8–2.2', '5.0–6.0', '最大化增肌，配合高强度训练'),
  ];

  static List<MacroReferenceRow> forGoal(FitnessGoal goal) =>
      goal == FitnessGoal.fatLoss ? fatLossTable : muscleGainTable;
}

class UserProfile {
  double height; // cm
  double weight; // kg
  int age;
  Gender gender;
  FitnessGoal goal;
  TrainingTime trainingTime;
  bool noStrengthTraining;

  // 可自定义的每千克摄入量
  double proteinPerKg;
  double carbsPerKg;

  UserProfile({
    this.height = 170,
    this.weight = 70,
    this.age = 25,
    this.gender = Gender.male,
    this.goal = FitnessGoal.fatLoss,
    this.trainingTime = TrainingTime.afterLunch,
    this.noStrengthTraining = false,
    double? proteinPerKg,
    double? carbsPerKg,
  })  : proteinPerKg = proteinPerKg ?? defaultProteinPerKg(goal),
        carbsPerKg = carbsPerKg ?? defaultCarbsPerKg(goal);

  static double defaultProteinPerKg(FitnessGoal g) =>
      g == FitnessGoal.fatLoss ? 2.0 : 1.8;

  static double defaultCarbsPerKg(FitnessGoal g) =>
      g == FitnessGoal.fatLoss ? 1.5 : 4.0;

  /// 当目标切换时重置为默认值（用户尚未手动调节时）
  void applyGoalDefaults() {
    proteinPerKg = defaultProteinPerKg(goal);
    carbsPerKg = defaultCarbsPerKg(goal);
  }

  double get dailyProtein => weight * proteinPerKg;
  double get dailyCarbs => weight * carbsPerKg;
  double get dailyCalories => dailyProtein * 4 + dailyCarbs * 4;

  bool get showNoStrengthOption => goal == FitnessGoal.fatLoss;

  UserProfile copyWith({
    double? height,
    double? weight,
    int? age,
    Gender? gender,
    FitnessGoal? goal,
    TrainingTime? trainingTime,
    bool? noStrengthTraining,
    double? proteinPerKg,
    double? carbsPerKg,
  }) =>
      UserProfile(
        height: height ?? this.height,
        weight: weight ?? this.weight,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        goal: goal ?? this.goal,
        trainingTime: trainingTime ?? this.trainingTime,
        noStrengthTraining: noStrengthTraining ?? this.noStrengthTraining,
        proteinPerKg: proteinPerKg ?? this.proteinPerKg,
        carbsPerKg: carbsPerKg ?? this.carbsPerKg,
      );

  Map<String, dynamic> toJson() => {
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender == Gender.male ? 'male' : 'female',
        'goal': goal == FitnessGoal.fatLoss ? 'fatLoss' : 'muscleGain',
        'trainingTime': trainingTime.name,
        'noStrengthTraining': noStrengthTraining,
        'proteinPerKg': proteinPerKg,
        'carbsPerKg': carbsPerKg,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        height: (j['height'] as num?)?.toDouble() ?? 170,
        weight: (j['weight'] as num?)?.toDouble() ?? 70,
        age: (j['age'] as num?)?.toInt() ?? 25,
        gender: j['gender'] == 'female' ? Gender.female : Gender.male,
        goal: j['goal'] == 'muscleGain'
            ? FitnessGoal.muscleGain
            : FitnessGoal.fatLoss,
        trainingTime: TrainingTime.values.firstWhere(
          (t) => t.name == j['trainingTime'],
          orElse: () => TrainingTime.afterLunch,
        ),
        noStrengthTraining: (j['noStrengthTraining'] as bool?) ?? false,
        proteinPerKg: (j['proteinPerKg'] as num?)?.toDouble(),
        carbsPerKg: (j['carbsPerKg'] as num?)?.toDouble(),
      );
}
