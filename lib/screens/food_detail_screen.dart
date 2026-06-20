import 'package:flutter/material.dart';
import '../models/food.dart';
import '../data/food_data.dart';
import '../utils/constants.dart';

class FoodDetailScreen extends StatefulWidget {
  /// If null, we're creating a new food
  final Food? food;
  final VoidCallback? onDeleted;

  const FoodDetailScreen({super.key, this.food, this.onDeleted});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _gramsPerUnitCtrl;
  late FoodUnit _unit;
  late String _category;
  late String? _subcategory;
  bool get _isNew => widget.food == null;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _unit = f?.unit ?? FoodUnit.grams100g;
    _category = f?.category ?? FoodCategory.uncategorized;
    _subcategory = f?.subcategory;
    _gramsPerUnitCtrl = TextEditingController(
      text: f?.gramsPerUnit?.toStringAsFixed(1) ?? '',
    );

    // 按件计的食物 → 控件显示每单位营养值
    if (f != null && _unit.isItemUnit && (f.gramsPerUnit ?? 0) > 0) {
      _proteinCtrl = TextEditingController(
        text: f.proteinPerUnit.toStringAsFixed(1),
      );
      _carbsCtrl = TextEditingController(
        text: f.carbsPerUnit.toStringAsFixed(1),
      );
    } else {
      _proteinCtrl = TextEditingController(
        text: f?.proteinPer100G.toStringAsFixed(1) ?? '0.0',
      );
      _carbsCtrl = TextEditingController(
        text: f?.carbsPer100G.toStringAsFixed(1) ?? '0.0',
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _gramsPerUnitCtrl.dispose();
    super.dispose();
  }

  Food? _buildFood() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return null;

    double protein;
    double carbs;
    final gpuText = _gramsPerUnitCtrl.text.trim();
    final gpu = _unit.isItemUnit && gpuText.isNotEmpty
        ? double.tryParse(gpuText)
        : null;

    if (_unit.isItemUnit && gpu != null && gpu > 0) {
      // 用户输入的是每单位营养值 → 转成每100g存储
      final p = double.tryParse(_proteinCtrl.text) ?? 0.0;
      final c = double.tryParse(_carbsCtrl.text) ?? 0.0;
      protein = p / gpu * 100;
      carbs = c / gpu * 100;
    } else {
      protein = double.tryParse(_proteinCtrl.text) ?? 0.0;
      carbs = double.tryParse(_carbsCtrl.text) ?? 0.0;
    }

    return Food(
      id: widget.food?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      unit: _unit,
      proteinPer100G: protein,
      carbsPer100G: carbs,
      category: _category,
      subcategory: _subcategory,
      gramsPerUnit: gpu,
    );
  }

  void _save() {
    final food = _buildFood();
    if (food == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入食物名称')),
      );
      return;
    }
    Navigator.pop(context, food);
  }

  void _delete() {
    if (_isNew) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除食物'),
        content: Text('确定要删除「${widget.food!.name}」吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleted?.call();
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '添加食物' : '编辑食物'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
              tooltip: '删除',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: '保存',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          // 食物图标
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: _categoryColor(theme),
              child: Text(
                _nameCtrl.text.isNotEmpty
                    ? _nameCtrl.text[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 名称
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '食物名称',
              hintText: '如：鸡胸肉、糙米饭',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // 计量单位选择
          DropdownButtonFormField<FoodUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(
              labelText: '计量单位',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              helperText: 'g/100g = 每100克，个/份/杯 = 按件计量',
              helperMaxLines: 2,
            ),
            items: FoodUnit.values
                .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              if (v != null) _unit = v;
            }),
          ),
          const SizedBox(height: 20),

          // 每单位克数（仅对"个/份/杯"显示）
          if (_unit.isItemUnit) ...[
            TextField(
              controller: _gramsPerUnitCtrl,
              decoration: InputDecoration(
                labelText: '每个${_unit.label}约多少克',
                hintText: '如：鸡蛋50g，馒头100g',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monitor_weight),
                suffixText: 'g/${_unit.label}',
                suffixStyle: TextStyle(color: Colors.grey[500]),
                helperText: '用于自动换算每${_unit.label}的营养值',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
          ],

          // 分类选择
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: '分类',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: PresetFoods.categories
                .followedBy([FoodCategory.uncategorized])
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _category = v!;
                // 切换分类时清除不适用的子分类
                if (_category != FoodCategory.staple) _subcategory = null;
              });
            },
          ),
          const SizedBox(height: 20),

          // 子分类（主食专用）
          if (_category == FoodCategory.staple)
            DropdownButtonFormField<String>(
              initialValue: _subcategory,
              decoration: const InputDecoration(
                labelText: '子分类',
                hintText: '选择子分类',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
              ),
              items: PresetFoods.subcategoriesOf(FoodCategory.staple)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subcategory = v),
            ),
          if (_category == FoodCategory.staple) const SizedBox(height: 20),

          // 蛋白质
          TextField(
            controller: _proteinCtrl,
            decoration: InputDecoration(
              labelText: '蛋白质',
              hintText: _unit.isItemUnit
                  ? '每${_unit.label}含多少克蛋白质'
                  : '每 100g 含多少克蛋白质',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.fitness_center),
              suffixText: _unit.isItemUnit ? 'g/${_unit.label}' : 'g/100g',
              suffixStyle: TextStyle(color: Colors.grey[500]),
              helperText: _unit.isItemUnit
                  ? '填写每${_unit.label}的蛋白质含量'
                  : null,
              helperStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // 碳水
          TextField(
            controller: _carbsCtrl,
            decoration: InputDecoration(
              labelText: '碳水',
              hintText: _unit.isItemUnit
                  ? '每${_unit.label}含多少克碳水'
                  : '每 100g 含多少克碳水',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.grain),
              suffixText: _unit.isItemUnit ? 'g/${_unit.label}' : 'g/100g',
              suffixStyle: TextStyle(color: Colors.grey[500]),
              helperText: _unit.isItemUnit
                  ? '填写每${_unit.label}的碳水含量'
                  : null,
              helperStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 32),

          // 营养信息预览
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('每${_unit.isItemUnit ? _unit.label : '100g'}营养成分',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _nutrientCol(
                          '蛋白质',
                          '${double.tryParse(_proteinCtrl.text)?.toStringAsFixed(1) ?? '0.0'}g',
                          Colors.orange),
                      _nutrientCol(
                          '碳水',
                          '${double.tryParse(_carbsCtrl.text)?.toStringAsFixed(1) ?? '0.0'}g',
                          Colors.green),
                    ],
                  ),
                  if (_unit.isItemUnit && _gramsPerUnitCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                        '1${_unit.label} ≈ ${_gramsPerUnitCtrl.text.trim()}g',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 保存按钮
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_isNew ? '添加食物' : '保存修改'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),

          if (!_isNew)
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('删除此食物', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Color _categoryColor(ThemeData theme) {
    switch (_category) {
      case FoodCategory.staple:
        return Colors.orange.withValues(alpha: 0.3);
      case FoodCategory.leanProtein:
        return Colors.red.withValues(alpha: 0.3);
      case FoodCategory.proteinPowder:
        return Colors.purple.withValues(alpha: 0.3);
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Widget _nutrientCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ],
    );
  }
}
