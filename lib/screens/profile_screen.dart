import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/food.dart';
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

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(text: widget.profile.height.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: widget.profile.weight.toStringAsFixed(1));
    _ageCtrl = TextEditingController(text: widget.profile.age.toString());
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final h = double.tryParse(_heightCtrl.text) ?? widget.profile.height;
    final w = double.tryParse(_weightCtrl.text) ?? widget.profile.weight;
    final a = int.tryParse(_ageCtrl.text) ?? widget.profile.age;
    widget.profile.height = h;
    widget.profile.weight = w;
    widget.profile.age = a;
    widget.onProfileChanged(widget.profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\u4e2a\u4eba\u8d44\u6599\u5df2\u4fdd\u5b58')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: theme.colorScheme.primaryContainer, child: Icon(Icons.person, size: 32, color: theme.colorScheme.primary)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\u4e2a\u4eba\u8d44\u6599', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('\u586b\u5199\u4fe1\u606f\u83b7\u53d6\u6bcf\u65e5\u8425\u517b\u63a8\u8350', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 20),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\u8eab\u4f53\u4fe1\u606f', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: '\u8eab\u9ad8 (cm)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.height)), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _weightCtrl, decoration: const InputDecoration(labelText: '\u4f53\u91cd (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight)), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _ageCtrl, decoration: const InputDecoration(labelText: '\u5e74\u9f84', border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)), keyboardType: TextInputType.number),
        ]))),
        const SizedBox(height: 12),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\u6027\u522b\u4e0e\u76ee\u6807', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('\u6027\u522b', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<Gender>(
            segments: const [ButtonSegment(value: Gender.male, label: Text('\u7537'), icon: Icon(Icons.male)), ButtonSegment(value: Gender.female, label: Text('\u5973'), icon: Icon(Icons.female))],
            selected: {p.gender},
            onSelectionChanged: (set) { setState(() => p.gender = set.first); _save(); },
          ),
          const SizedBox(height: 12),
          Text('\u76ee\u6807', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<FitnessGoal>(
            segments: const [ButtonSegment(value: FitnessGoal.fatLoss, label: Text('\u51cf\u8102'), icon: Icon(Icons.trending_down)), ButtonSegment(value: FitnessGoal.muscleGain, label: Text('\u589e\u808c'), icon: Icon(Icons.trending_up))],
            selected: {p.goal},
            onSelectionChanged: (set) { setState(() => p.goal = set.first); _save(); },
          ),
        ]))),
        const SizedBox(height: 12),

        Card(color: theme.colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            Icon(Icons.track_changes, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('\u6bcf\u65e5\u8425\u517b\u76ee\u6807', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: theme.colorScheme.onPrimaryContainer)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _TargetColumn(icon: Icons.fitness_center, label: '\u86cb\u767d\u8d28', value: '${p.dailyProtein.toStringAsFixed(0)}g', color: theme.colorScheme.onPrimaryContainer),
            Container(height: 50, width: 1, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2)),
            _TargetColumn(icon: Icons.grain, label: '\u78b3\u6c34', value: '${p.dailyCarbs.toStringAsFixed(0)}g', color: theme.colorScheme.onPrimaryContainer),
            Container(height: 50, width: 1, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2)),
            _TargetColumn(icon: Icons.local_fire_department, label: '卡路里', value: p.dailyCalories.toStringAsFixed(0), color: theme.colorScheme.onPrimaryContainer),
          ]),
        ]))),
        const SizedBox(height: 12),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\u63a8\u8350\u8bf4\u660e', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            p.goal == FitnessGoal.fatLoss
              ? '\u51cf\u8102\u671f\u9ad8\u86cb\u767d\u6444\u5165\uff08${p.weight.toStringAsFixed(0)}kg \u00d7 2.0g/kg\uff09\u6709\u52a9\u4e8e\u4fdd\u7559\u808c\u8089\uff0c\u9002\u91cf\u78b3\u6c34\u7ef4\u6301\u8bad\u7ec3\u8868\u73b0\u3002'
              : '\u589e\u808c\u671f\u9002\u91cf\u86cb\u767d\uff08${p.weight.toStringAsFixed(0)}kg \u00d7 1.8g/kg\uff09\u914d\u5408\u5145\u8db3\u78b3\u6c34\u4e3a\u8bad\u7ec3\u4f9b\u80fd\uff0c\u4fc3\u8fdb\u808c\u8089\u5408\u6210\u3002',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ]))),
        const SizedBox(height: 16),

        // Templates card
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => TemplateListScreen(
                  foods: widget.foods,
                  templates: widget.templates,
                ),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('配餐模板', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('共 ${widget.templates.length} 个已保存的模板', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('\u4fdd\u5b58\u4e2a\u4eba\u8d44\u6599'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
      ],
    );
  }
}

class _TargetColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TargetColumn({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color.withValues(alpha: 0.7), size: 28),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.7))),
    ]));
  }
}