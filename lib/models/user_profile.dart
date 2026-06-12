enum Gender { male, female }
enum FitnessGoal { fatLoss, muscleGain }

/// 每千克摄入参考数据行
class MacroReferenceRow {
  final String intensity;
  final String proteinRange;
  final String carbRange;
  final String note;

  const MacroReferenceRow(this.intensity, this.proteinRange, this.carbRange, this.note);

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

  // 可自定义的每千克摄入量
  double proteinPerKg;
  double carbsPerKg;

  UserProfile({
    this.height = 170,
    this.weight = 70,
    this.age = 25,
    this.gender = Gender.male,
    this.goal = FitnessGoal.fatLoss,
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

  UserProfile copy() => UserProfile(
        height: height,
        weight: weight,
        age: age,
        gender: gender,
        goal: goal,
        proteinPerKg: proteinPerKg,
        carbsPerKg: carbsPerKg,
      );

  Map<String, dynamic> toJson() => {
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender == Gender.male ? 'male' : 'female',
        'goal': goal == FitnessGoal.fatLoss ? 'fatLoss' : 'muscleGain',
        'proteinPerKg': proteinPerKg,
        'carbsPerKg': carbsPerKg,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        height: (j['height'] as num?)?.toDouble() ?? 170,
        weight: (j['weight'] as num?)?.toDouble() ?? 70,
        age: (j['age'] as num?)?.toInt() ?? 25,
        gender: j['gender'] == 'female' ? Gender.female : Gender.male,
        goal: j['goal'] == 'muscleGain' ? FitnessGoal.muscleGain : FitnessGoal.fatLoss,
        proteinPerKg: (j['proteinPerKg'] as num?)?.toDouble(),
        carbsPerKg: (j['carbsPerKg'] as num?)?.toDouble(),
      );
}
