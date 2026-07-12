import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/food.dart';
import '../data/nutrition_reference.dart';
import '../widgets/nutrient_display.dart';
import 'nutrition_reference_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;
  final List<Food> foods;
  final List<MealTemplate> templates;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.foods,
    required this.templates,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _proteinKgCtrl;
  late TextEditingController _carbsKgCtrl;
  late TextEditingController _restCarbsKgCtrl;
  late TextEditingController _fatKgCtrl;

  // 标记用户是否手动调整过每千克值（切换目标时不覆盖）
  bool _userTweakedProtein = false;
  bool _userTweakedCarbs = false;

  // 查表推荐状态
  String? _recommendationNote;
  (double, double, double)? _recommendedFactor; // (trainCarbs, restCarbs, protein)
  bool _hasAppliedRecommendation = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _heightCtrl = TextEditingController(text: p.height.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: p.weight.toStringAsFixed(1));
    _ageCtrl = TextEditingController(text: p.age.toString());
    _proteinKgCtrl =
        TextEditingController(text: p.proteinPerKg.toStringAsFixed(1));
    _carbsKgCtrl = TextEditingController(text: p.carbsPerKg.toStringAsFixed(1));
    _restCarbsKgCtrl =
        TextEditingController(text: p.restCarbsPerKg.toStringAsFixed(1));
    _fatKgCtrl =
        TextEditingController(text: p.fatPerKg.toStringAsFixed(1));
    // 页面恢复时自动查表推荐
    _lookupRecommendation();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      final p = widget.profile;
      _heightCtrl.text = p.height.toStringAsFixed(0);
      _weightCtrl.text = p.weight.toStringAsFixed(1);
      _ageCtrl.text = p.age.toString();
      _proteinKgCtrl.text = p.proteinPerKg.toStringAsFixed(1);
      _carbsKgCtrl.text = p.carbsPerKg.toStringAsFixed(1);
      _restCarbsKgCtrl.text = p.restCarbsPerKg.toStringAsFixed(1);
      _fatKgCtrl.text = p.fatPerKg.toStringAsFixed(1);
      _userTweakedProtein = false;
      _userTweakedCarbs = false;
      _hasAppliedRecommendation = false;
      _lookupRecommendation();
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _proteinKgCtrl.dispose();
    _carbsKgCtrl.dispose();
    _restCarbsKgCtrl.dispose();
    _fatKgCtrl.dispose();
    super.dispose();
  }

  void save() {
    final h = double.tryParse(_heightCtrl.text) ?? widget.profile.height;
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final a = int.tryParse(_ageCtrl.text) ?? widget.profile.age;
    final pk =
        double.tryParse(_proteinKgCtrl.text) ?? widget.profile.proteinPerKg;
    final ck = double.tryParse(_carbsKgCtrl.text) ?? widget.profile.carbsPerKg;
    final rck = double.tryParse(_restCarbsKgCtrl.text) ?? widget.profile.restCarbsPerKg;
    final fk = double.tryParse(_fatKgCtrl.text) ?? widget.profile.fatPerKg;
    widget.profile.height = h;
    widget.profile.weight = w;
    widget.profile.age = a;
    widget.profile.proteinPerKg = pk;
    widget.profile.carbsPerKg = ck;
    widget.profile.restCarbsPerKg = rck;
    widget.profile.fatPerKg = fk;
    widget.onProfileChanged(widget.profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('个人资料已保存')),
    );
  }

  /// 切页时自动保存，不弹提示
  void silentSave() {
    final h = double.tryParse(_heightCtrl.text) ?? widget.profile.height;
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final a = int.tryParse(_ageCtrl.text) ?? widget.profile.age;
    final pk =
        double.tryParse(_proteinKgCtrl.text) ?? widget.profile.proteinPerKg;
    final ck = double.tryParse(_carbsKgCtrl.text) ?? widget.profile.carbsPerKg;
    final rck = double.tryParse(_restCarbsKgCtrl.text) ?? widget.profile.restCarbsPerKg;
    final fk = double.tryParse(_fatKgCtrl.text) ?? widget.profile.fatPerKg;
    widget.profile.height = h;
    widget.profile.weight = w;
    widget.profile.age = a;
    widget.profile.proteinPerKg = pk;
    widget.profile.carbsPerKg = ck;
    widget.profile.restCarbsPerKg = rck;
    widget.profile.fatPerKg = fk;
    widget.onProfileChanged(widget.profile);
  }

  void _onGoalChanged(FitnessGoal newGoal) {
    setState(() {
      widget.profile.goal = newGoal;
      // 若用户未手动调过，则自动设为目标默认值
      if (!_userTweakedProtein) {
        widget.profile.proteinPerKg = UserProfile.defaultProteinPerKg(newGoal);
        _proteinKgCtrl.text = widget.profile.proteinPerKg.toStringAsFixed(1);
      }
      if (!_userTweakedCarbs) {
        widget.profile.carbsPerKg = UserProfile.defaultCarbsPerKg(newGoal);
        _carbsKgCtrl.text = widget.profile.carbsPerKg.toStringAsFixed(1);
        widget.profile.restCarbsPerKg = UserProfile.defaultCarbsPerKg(newGoal);
        _restCarbsKgCtrl.text = widget.profile.restCarbsPerKg.toStringAsFixed(1);
      }
    });
    save();
  }

  /// 根据身高/体重/性别/目标/训练情况查表获取推荐值
  void _lookupRecommendation() {
    final p = widget.profile;
    final h = double.tryParse(_heightCtrl.text) ?? p.height;
    final w = double.tryParse(_weightCtrl.text) ?? p.weight;
    final isStrengthTraining = !p.noStrengthTraining;
    final result = NutritionReference.lookupRecommended(
      isMale: p.gender == Gender.male,
      heightCm: h.round(),
      weightKg: w.round(),
      isStrengthTraining: isStrengthTraining,
      goal: p.goal,
    );
    if (result != null) {
      _recommendedFactor = result;
      _recommendationNote = NutritionReference.recommendationNote(
        isMale: p.gender == Gender.male,
        heightCm: h.round(),
        weightKg: w.round(),
        isStrengthTraining: isStrengthTraining,
        goal: p.goal,
      );
      // 只计算推荐值，不修改输入框或 profile 对象
      // 用户需手动点击「应用推荐」才会写入
    } else {
      _recommendedFactor = null;
      _recommendationNote = '当前身高/体重组合暂无参考数据';
      _hasAppliedRecommendation = false;
    }
  }

  void _applyRecommendation() {
    if (_recommendedFactor == null) return;
    final p = widget.profile;
    p.proteinPerKg = _recommendedFactor!.$3;
    p.carbsPerKg = _recommendedFactor!.$1;
    p.restCarbsPerKg = _recommendedFactor!.$2;
    _proteinKgCtrl.text = p.proteinPerKg.toStringAsFixed(1);
    _carbsKgCtrl.text = p.carbsPerKg.toStringAsFixed(1);
    _restCarbsKgCtrl.text = p.restCarbsPerKg.toStringAsFixed(1);
    _hasAppliedRecommendation = true;
    _userTweakedProtein = false;
    _userTweakedCarbs = false;
    setState(() {});
    save();
  }

  void _showRefTable() =>
      NutritionReferenceSheet.show(context, widget.profile);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- 头部 ----
        Row(children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  size: 32, color: theme.colorScheme.primary)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('个人资料',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('填写信息获取每日营养推荐',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 20),

        // ---- 身体信息 ----
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('身体信息',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: _heightCtrl,
                                decoration: const InputDecoration(
                                    labelText: '身高 (cm)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.height)),
                                keyboardType: TextInputType.number,
                                onChanged: (_) {})),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                controller: _weightCtrl,
                                decoration: const InputDecoration(
                                    labelText: '体重 (kg)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.monitor_weight)),
                                keyboardType: TextInputType.number,
                                onChanged: (_) {})),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _ageCtrl,
                          decoration: const InputDecoration(
                              labelText: '年龄',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.cake)),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {}),
                    ]))),
        const SizedBox(height: 12),

        // ---- 性别与目标 ----
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('性别与目标',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text('性别',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const SizedBox(height: 8),
                      SegmentedButton<Gender>(
                        segments: const [
                          ButtonSegment(
                              value: Gender.male,
                              label: Text('男'),
                              icon: Icon(Icons.male)),
                          ButtonSegment(
                              value: Gender.female,
                              label: Text('女'),
                              icon: Icon(Icons.female)),
                        ],
                        selected: {p.gender},
                        onSelectionChanged: (set) {
                          setState(() => p.gender = set.first);
                          save();
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('目标',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const SizedBox(height: 8),
                      SegmentedButton<FitnessGoal>(
                        segments: const [
                          ButtonSegment(
                              value: FitnessGoal.fatLoss,
                              label: Text('减脂'),
                              icon: Icon(Icons.trending_down)),
                          ButtonSegment(
                              value: FitnessGoal.muscleGain,
                              label: Text('增肌'),
                              icon: Icon(Icons.trending_up)),
                        ],
                        selected: {p.goal},
                        onSelectionChanged: (set) => _onGoalChanged(set.first),
                      ),
                      const SizedBox(height: 16),
                      // 力量训练开关
                      if (p.goal == FitnessGoal.fatLoss)
                        SwitchListTile(
                          title: const Text('不做力量训练（纯饮食控制）',
                              style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            p.noStrengthTraining ? '无训练时间概念' : '需选择训练时段',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          value: p.noStrengthTraining,
                          onChanged: (v) {
                            setState(() => p.noStrengthTraining = v);
                            _lookupRecommendation();
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      // 训练时间（仅力量训练时显示）
                      if (!p.noStrengthTraining) ...[
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '训练时间',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TrainingTime>(
                              value: p.trainingTime,
                              isDense: true,
                              isExpanded: true,
                              items: TrainingTime.values
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text('${t.icon} ${t.label}',
                                            style: const TextStyle(fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => p.trainingTime = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ]))),
        const SizedBox(height: 12),

        // ---- 每千克摄入量（可自定义） ----
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.tune,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('每千克摄入量 (g/kg)',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showRefTable,
                          icon:
                              const Icon(Icons.table_chart_outlined, size: 18),
                          label:
                              const Text('参考表', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        '根据下面的参考表调整每千克摄入量，每日总量会自动更新',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      // 蛋白质 + 训练日碳水 + (可选)休息日碳水
                      if (!widget.profile.noStrengthTraining) ...[
                        // 有力量训练 → 显示三列
                        Row(children: [
                          Expanded(
                              child: TextField(
                            controller: _proteinKgCtrl,
                            decoration: const InputDecoration(
                              labelText: '蛋白质 (g/kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.fitness_center),
                              isDense: true,
                              helperText: '训练日/休息日',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              _userTweakedProtein = true;
                              if (_hasAppliedRecommendation) {
                                _hasAppliedRecommendation = false;
                              }
                            },
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextField(
                            controller: _carbsKgCtrl,
                            decoration: const InputDecoration(
                              labelText: '碳水·训 (g/kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flash_on),
                              isDense: true,
                              helperText: '训练日',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              _userTweakedCarbs = true;
                              if (_hasAppliedRecommendation) {
                                _hasAppliedRecommendation = false;
                              }
                            },
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextField(
                            controller: _restCarbsKgCtrl,
                            decoration: const InputDecoration(
                              labelText: '碳水·休 (g/kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.bedtime),
                              isDense: true,
                              helperText: '休息日',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              _userTweakedCarbs = true;
                              if (_hasAppliedRecommendation) {
                                _hasAppliedRecommendation = false;
                              }
                            },
                          )),
                        ]),
                      ] else ...[
                        // 无力训 → 显示两列
                        Row(children: [
                          Expanded(
                              child: TextField(
                            controller: _proteinKgCtrl,
                            decoration: const InputDecoration(
                              labelText: '蛋白质 (g/kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.fitness_center),
                              isDense: true,
                              helperText: '调节后自动计算',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              _userTweakedProtein = true;
                              if (_hasAppliedRecommendation) {
                                _hasAppliedRecommendation = false;
                              }
                            },
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: TextField(
                            controller: _carbsKgCtrl,
                            decoration: const InputDecoration(
                              labelText: '碳水 (g/kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.grain),
                              isDense: true,
                              helperText: '调节后自动计算',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              _userTweakedCarbs = true;
                              if (_hasAppliedRecommendation) {
                                _hasAppliedRecommendation = false;
                              }
                            },
                          )),
                        ]),
                      ],
                      // 脂肪（统一放一行，力训/无力训都显示）
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: TextField(
                          controller: _fatKgCtrl,
                          decoration: const InputDecoration(
                            labelText: '脂肪上限 (g/kg)',
                            hintText: '默认 0.8',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.water_drop),
                            isDense: true,
                            helperText: '超上限时今日页面提示',
                            helperStyle: TextStyle(fontSize: 11),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        )),
                        const Spacer(),
                      ]),
                      // 查表推荐提示
                      if (_recommendationNote != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Colors.blue[600]),
                                  const SizedBox(width: 6),
                                  Text('查表推荐',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700])),
                                  if (!_hasAppliedRecommendation) ...[
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _applyRecommendation,
                                      icon: const Icon(Icons.check_circle_outline,
                                          size: 16),
                                      label: const Text('应用推荐',
                                          style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ] else ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check,
                                              size: 13, color: Colors.green[700]),
                                          const SizedBox(width: 3),
                                          Text('已应用',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green[700])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_recommendationNote!,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ]))),
        const SizedBox(height: 12),

        // ---- 每日营养目标（实时预览） ----
        Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.track_changes,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('每日营养目标',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.colorScheme.onPrimaryContainer)),
                    const Spacer(),
                    if (_hasAppliedRecommendation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 13,
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text('查表推荐',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    NutrientColumn(
                        icon: Icons.fitness_center,
                        label: '蛋白质',
                        value: '${_calcDailyProtein().toStringAsFixed(0)}g',
                        color: theme.colorScheme.onPrimaryContainer),
                    Container(
                        height: 50,
                        width: 1,
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.2)),
                    NutrientColumn(
                        icon: Icons.flash_on,
                        label: '碳水·训',
                        value: '${_calcDailyCarbs().toStringAsFixed(0)}g',
                        color: theme.colorScheme.onPrimaryContainer),
                    if (!widget.profile.noStrengthTraining) ...[
                      Container(
                          height: 50,
                          width: 1,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.2)),
                      NutrientColumn(
                          icon: Icons.bedtime,
                          label: '碳水·休',
                          value: '${_calcDailyRestCarbs().toStringAsFixed(0)}g',
                          color: theme.colorScheme.onPrimaryContainer),
                    ],
                    ]),
                ]))),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---- 实时计算（考虑用户输入的字段值） ----
  double _calcDailyProtein() {
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final pk =
        double.tryParse(_proteinKgCtrl.text) ?? widget.profile.proteinPerKg;
    return w * pk;
  }

  double _calcDailyCarbs() {
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final ck = double.tryParse(_carbsKgCtrl.text) ?? widget.profile.carbsPerKg;
    return w * ck;
  }

  double _calcDailyRestCarbs() {
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final rck = double.tryParse(_restCarbsKgCtrl.text) ?? widget.profile.restCarbsPerKg;
    return w * rck;
  }
}
