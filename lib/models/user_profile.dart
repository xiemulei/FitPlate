enum Gender { male, female }
enum FitnessGoal { fatLoss, muscleGain }

class UserProfile {
  double height; // cm
  double weight; // kg
  int age;
  Gender gender;
  FitnessGoal goal;

  UserProfile({
    this.height = 170,
    this.weight = 70,
    this.age = 25,
    this.gender = Gender.male,
    this.goal = FitnessGoal.fatLoss,
  });

  double get dailyProtein {
    switch (goal) {
      case FitnessGoal.fatLoss:
        return weight * 2.0;
      case FitnessGoal.muscleGain:
        return weight * 1.8;
    }
  }

  double get dailyCarbs {
    switch (goal) {
      case FitnessGoal.fatLoss:
        return weight * 1.5;
      case FitnessGoal.muscleGain:
        return weight * 4.0;
    }
  }

  double get dailyCalories => dailyProtein * 4 + dailyCarbs * 4;

  UserProfile copy() => UserProfile(
    height: height, weight: weight, age: age,
    gender: gender, goal: goal,
  );

  Map<String, dynamic> toJson() => {
    'height': height, 'weight': weight, 'age': age,
    'gender': gender == Gender.male ? 'male' : 'female',
    'goal': goal == FitnessGoal.fatLoss ? 'fatLoss' : 'muscleGain',
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    height: (j['height'] as num?)?.toDouble() ?? 170,
    weight: (j['weight'] as num?)?.toDouble() ?? 70,
    age: (j['age'] as num?)?.toInt() ?? 25,
    gender: j['gender'] == 'female' ? Gender.female : Gender.male,
    goal: j['goal'] == 'muscleGain' ? FitnessGoal.muscleGain : FitnessGoal.fatLoss,
  );
}
