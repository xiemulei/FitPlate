import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/food.dart';
import '../data/nutrition_reference.dart';
import 'template_list_screen.dart';

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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _proteinKgCtrl;
  late TextEditingController _carbsKgCtrl;

  // 标记用户是否手动调整过每千克值（切换目标时不覆盖）
  bool _userTweakedProtein = false;
  bool _userTweakedCarbs = false;

  // 查表推荐状态
  String? _recommendationNote;
  (double, double)? _recommendedFactor; // ($1=carbsPerKg, $2=proteinPerKg)
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
    // 页面恢复时自动查表推荐
    _lookupRecommendation();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _proteinKgCtrl.dispose();
    _carbsKgCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final h = double.tryParse(_heightCtrl.text) ?? widget.profile.height;
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final a = int.tryParse(_ageCtrl.text) ?? widget.profile.age;
    final pk =
        double.tryParse(_proteinKgCtrl.text) ?? widget.profile.proteinPerKg;
    final ck = double.tryParse(_carbsKgCtrl.text) ?? widget.profile.carbsPerKg;
    widget.profile.height = h;
    widget.profile.weight = w;
    widget.profile.age = a;
    widget.profile.proteinPerKg = pk;
    widget.profile.carbsPerKg = ck;
    widget.onProfileChanged(widget.profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('个人资料已保存')),
    );
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
      }
    });
    _save();
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
      _hasAppliedRecommendation = true;
      // 自动填入查表推荐值
      p.proteinPerKg = result.$2;
      p.carbsPerKg = result.$1;
      _proteinKgCtrl.text = result.$2.toStringAsFixed(1);
      _carbsKgCtrl.text = result.$1.toStringAsFixed(1);
      _userTweakedProtein = false;
      _userTweakedCarbs = false;
    } else {
      _recommendedFactor = null;
      _recommendationNote = '当前身高/体重组合暂无参考数据';
      _hasAppliedRecommendation = false;
    }
  }

  void _applyRecommendation() {
    if (_recommendedFactor == null) return;
    final p = widget.profile;
    p.proteinPerKg = _recommendedFactor!.$2;
    p.carbsPerKg = _recommendedFactor!.$1;
    _proteinKgCtrl.text = p.proteinPerKg.toStringAsFixed(1);
    _carbsKgCtrl.text = p.carbsPerKg.toStringAsFixed(1);
    _hasAppliedRecommendation = true;
    _userTweakedProtein = false;
    _userTweakedCarbs = false;
    setState(() {});
  }

  void _showRefTable() {
    final goal = widget.profile.goal;
    final rows = MacroReferenceRow.forGoal(goal);
    final title = goal == FitnessGoal.fatLoss ? '减脂 - 每千克摄入参考' : '增肌 - 每千克摄入参考';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // 拖拽指示条
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '以下为常见推荐范围，可据此调整上方的每千克摄入量',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // 表头
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      _th('强度', flex: 1),
                      _th('蛋白质 (g/kg)', flex: 2),
                      _th('碳水 (g/kg)', flex: 2),
                    ]),
                  ),
                  // 表体
                  ...rows.asMap().entries.map((e) {
                    final idx = e.key;
                    final row = e.value;
                    final isLast = idx == rows.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: idx.isEven
                            ? Colors.transparent
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(8))
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(children: [
                        _td(row.intensity, flex: 1),
                        _td(row.proteinRange, flex: 2),
                        _td(row.carbRange, flex: 2),
                      ]),
                    );
                  }),
                  const SizedBox(height: 12),
                  // 备注
                  ...rows.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('· ',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12)),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12),
                                  children: [
                                    TextSpan(
                                        text: r.intensity,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    TextSpan(text: '：${r.note}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _th(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _td(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

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
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                controller: _weightCtrl,
                                decoration: const InputDecoration(
                                    labelText: '体重 (kg)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.monitor_weight)),
                                keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _ageCtrl,
                          decoration: const InputDecoration(
                              labelText: '年龄',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.cake)),
                          keyboardType: TextInputType.number),
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
                          _save();
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
                      Text('训练时间',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TrainingTime.values
                            .map((t) => ChoiceChip(
                                  label: Text('${t.icon} ${t.label}',
                                      style: const TextStyle(fontSize: 13)),
                                  selected: p.trainingTime == t,
                                  onSelected: (_) {
                                    setState(() => p.trainingTime = t);
                                    _save();
                                  },
                                ))
                            .toList(),
                      ),
                      if (p.goal == FitnessGoal.fatLoss) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('不做力量训练（纯饮食控制）',
                              style: TextStyle(fontSize: 14)),
                          value: p.noStrengthTraining,
                          onChanged: (v) {
                            setState(() => p.noStrengthTraining = v);
                            _lookupRecommendation();
                            _save();
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
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
                            setState(() {});
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
                            setState(() {});
                          },
                        )),
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
                    _TargetColumn(
                        icon: Icons.fitness_center,
                        label: '蛋白质',
                        value: '${_calcDailyProtein().toStringAsFixed(0)}g',
                        color: theme.colorScheme.onPrimaryContainer),
                    Container(
                        height: 50,
                        width: 1,
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.2)),
                    _TargetColumn(
                        icon: Icons.grain,
                        label: '碳水',
                        value: '${_calcDailyCarbs().toStringAsFixed(0)}g',
                        color: theme.colorScheme.onPrimaryContainer),
                    Container(
                        height: 50,
                        width: 1,
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.2)),
                    _TargetColumn(
                        icon: Icons.local_fire_department,
                        label: '卡路里',
                        value: _calcDailyCalories().toStringAsFixed(0),
                        color: theme.colorScheme.onPrimaryContainer),
                  ]),
                ]))),
        const SizedBox(height: 12),

        // ---- 推荐说明 ----
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('推荐说明',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        p.goal == FitnessGoal.fatLoss
                            ? _hasAppliedRecommendation
                                ? '减脂期（纯饮食控制），基于身高${p.height.toStringAsFixed(0)}cm / 体重${p.weight.toStringAsFixed(0)}kg / ${p.gender == Gender.male ? "男" : "女"} 的参考表推荐：蛋白质 ${p.proteinPerKg.toStringAsFixed(1)} g/kg（每日 ${_calcDailyProtein().toStringAsFixed(0)} g），碳水 ${p.carbsPerKg.toStringAsFixed(1)} g/kg（每日 ${_calcDailyCarbs().toStringAsFixed(0)} g）。'
                                : '减脂期高蛋白摄入（${p.weight.toStringAsFixed(0)}kg × ${p.proteinPerKg.toStringAsFixed(1)}g/kg）有助于保留肌肉，适量碳水维持训练表现。'
                            : '增肌期适量蛋白（${p.weight.toStringAsFixed(0)}kg × ${p.proteinPerKg.toStringAsFixed(1)}g/kg）配合充足碳水为训练供能，促进肌肉合成。',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ]))),
        const SizedBox(height: 16),

        // ---- 配餐模板 ----
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateListScreen(
                    foods: widget.foods,
                    templates: widget.templates,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.restaurant_menu, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('配餐模板',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('共 ${widget.templates.length} 个已保存的模板',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ]),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---- 保存按钮 ----
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('保存个人资料'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
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

  double _calcDailyCalories() =>
      _calcDailyProtein() * 4 + _calcDailyCarbs() * 4;
}

class _TargetColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TargetColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Icon(icon, color: color.withValues(alpha: 0.7), size: 28),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      Text(label,
          style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.7))),
    ]));
  }
}
