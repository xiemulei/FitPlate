import 'package:flutter/material.dart';
import '../models/food.dart';
import '../data/food_data.dart';
import '../utils/constants.dart';
import 'food_detail_screen.dart';

class FoodLibraryScreen extends StatefulWidget {
  final List<Food> foods;
  final ValueChanged<List<Food>> onFoodsChanged;

  const FoodLibraryScreen({
    super.key,
    required this.foods,
    required this.onFoodsChanged,
  });

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  // ─────────────────────────────────────────────
  // 搜索结果
  // ─────────────────────────────────────────────

  List<Food> get _searchResults {
    if (!_isSearching) return [];
    final q = _searchQuery.trim().toLowerCase();
    return widget.foods.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  // ─────────────────────────────────────────────
  // 分类分组（浏览模式）
  // ─────────────────────────────────────────────

  List<_CategoryGroup> _buildGroups() {
    final byCat = <String, List<Food>>{};
    for (final f in widget.foods) {
      byCat.putIfAbsent(f.category, () => []).add(f);
    }

    // 自定义排序：主食 → 蛋白质-纯瘦肉 → 蛋白质-蛋白粉 → 其他
    const catOrder = [
      FoodCategory.staple,
      FoodCategory.leanProtein,
      FoodCategory.proteinPowder,
    ];
    final result = <_CategoryGroup>[];

    void addCategory(String cat) {
      final foods = byCat.remove(cat);
      if (foods == null || foods.isEmpty) return;

      final subGroups = <_SubGroup>[];
      final unsubbed = <Food>[];
      final assignedIds = <String>{};

      // 按子分类分组
      for (final f in foods) {
        if (f.subcategory != null && f.subcategory!.isNotEmpty) {
          final sub = f.subcategory!;
          final idx = subGroups.indexWhere((g) => g.name == sub);
          if (idx != -1) {
            subGroups[idx].foods.add(f);
          } else {
            subGroups.add(_SubGroup(sub, [f]));
          }
          assignedIds.add(f.id);
        }
      }
      unsubbed.addAll(foods.where((f) => !assignedIds.contains(f.id)));

      result.add(_CategoryGroup(cat, subGroups, unsubbed));
    }

    for (final cat in catOrder) addCategory(cat);
    // 剩余分类
    for (final cat in byCat.keys.toList()) addCategory(cat);

    return result;
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.foods.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: _isSearching
              ? _buildSearchResults(theme)
              : _buildCategoryList(theme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('还没有食物',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('点击右下角 + 添加食物', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => widget.onFoodsChanged(PresetFoods.all),
            icon: const Icon(Icons.download),
            label: const Text('载入预设食物库'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索食物...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ── 搜索结果 ──

  Widget _buildSearchResults(ThemeData theme) {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text('没有找到 "$_searchQuery"',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: results.length,
      itemBuilder: (_, i) => _buildFoodCard(theme, results[i]),
    );
  }

  // ── 分类浏览 ──

  Widget _buildCategoryList(ThemeData theme) {
    final groups = _buildGroups();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: groups.length,
      itemBuilder: (_, i) => _buildCategoryTile(theme, groups[i]),
    );
  }

  Widget _buildCategoryTile(ThemeData theme, _CategoryGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        collapsedShape: const RoundedRectangleBorder(),
        shape: const RoundedRectangleBorder(),
        leading: CircleAvatar(
          backgroundColor:
              _categoryColor(group.category, theme).withValues(alpha: 0.2),
          child: Icon(_categoryIcon(group.category),
              size: 20, color: _categoryColor(group.category, theme)),
        ),
        title: Text(group.category,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${group.totalCount} 种食物',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        children: [
          // 子分类
          if (group.subGroups.isNotEmpty)
            for (final sub in group.subGroups) ...[
              _buildSubheader(theme, sub.name),
              for (final food in sub.foods) _buildFoodCard(theme, food),
            ],
          // 该分类下未归入子类的食物
          if (group.unsubcategorized.isNotEmpty) ...[
            if (group.subGroups.isNotEmpty) _buildSubheader(theme, '其他'),
            for (final food in group.unsubcategorized)
              _buildFoodCard(theme, food),
          ],
        ],
      ),
    );
  }

  Widget _buildSubheader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  // ── 食物卡片 ──

  Widget _buildFoodCard(ThemeData theme, Food food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _categoryColor(food.category, theme),
          child: Text(
            food.name.isNotEmpty ? food.name[0] : '?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(food.name,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            Text('(${food.unitLabel})',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        subtitle: Text(
          food.nutritionLabel,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () async {
          final result = await Navigator.push<Food>(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(
                food: food,
                onDeleted: () {
                  final updated =
                      widget.foods.where((f) => f.id != food.id).toList();
                  widget.onFoodsChanged(updated);
                },
              ),
            ),
          );
          if (result != null && mounted) {
            final updated =
                widget.foods.map((f) => f.id == food.id ? result : f).toList();
            widget.onFoodsChanged(updated);
          }
        },
      ),
    );
  }

  // ── 图标/颜色 ──

  IconData _categoryIcon(String category) {
    switch (category) {
      case FoodCategory.staple:
        return Icons.rice_bowl;
      case FoodCategory.leanProtein:
        return Icons.cookie;
      case FoodCategory.proteinPowder:
        return Icons.bolt;
      default:
        return Icons.restaurant;
    }
  }

  Color _categoryColor(String category, ThemeData theme) {
    switch (category) {
      case FoodCategory.staple:
        return Colors.orange;
      case FoodCategory.leanProtein:
        return Colors.red;
      case FoodCategory.proteinPowder:
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }
}

// ── 辅助数据类 ──

class _CategoryGroup {
  final String category;
  final List<_SubGroup> subGroups;
  final List<Food> unsubcategorized;

  _CategoryGroup(this.category, this.subGroups, this.unsubcategorized);

  int get totalCount {
    var count = unsubcategorized.length;
    for (final sub in subGroups) {
      count += sub.foods.length;
    }
    return count;
  }
}

class _SubGroup {
  final String name;
  final List<Food> foods;
  _SubGroup(this.name, this.foods);
}
