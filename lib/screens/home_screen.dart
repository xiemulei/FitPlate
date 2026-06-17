import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/cycle.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../data/food_data.dart';
import 'food_library_screen.dart';
import 'food_detail_screen.dart';
import 'meal_planner_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';
import 'cycle_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Food> _foods = [];
  List<MealTemplate> _templates = [];
  List<TrainingCycle> _cycles = [];
  UserProfile _profile = UserProfile();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final t = await StorageService.loadTemplates();
    final pr = await StorageService.loadProfile();
    final c = await StorageService.loadCycles();
    final customFoods = await StorageService.loadFoods();
    setState(() {
      _templates = t;
      _cycles = c;
      _profile = pr;
      _foods = [
        ...PresetFoods.all,
        ...customFoods.where((f) => !PresetFoods.all.any((p) => p.id == f.id)),
      ];
    });
  }

  Future<void> _onProfileChanged(UserProfile p) async {
    setState(() => _profile = p);
    await StorageService.saveProfile(p);
  }

  Future<void> _onCyclesChanged(List<TrainingCycle> cycles) async {
    setState(() => _cycles = cycles);
    await StorageService.saveCycles(cycles);
  }

  Future<void> _onFoodsChanged(List<Food> foods) async {
    setState(() => _foods = foods);
    await StorageService.saveFoods(
        foods.where((f) => !PresetFoods.all.contains(f)).toList());
  }

  Future<void> _addFood() async {
    final result = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (_) => const FoodDetailScreen()),
    );
    if (result != null) {
      final foods = [..._foods, result];
      setState(() => _foods = foods);
      await StorageService.saveFoods(
          foods.where((f) => !PresetFoods.all.contains(f)).toList());
    }
  }

  /// 从 Today 页跳转到历史记录（全屏 push）
  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('饮食历史记录'),
            leading: const BackButton(),
          ),
          body: HistoryScreen(foods: _foods),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // 标签0：今天
      TodayScreen(
        cycles: _cycles,
        templates: _templates,
        foods: _foods,
        onGoToCycle: () => setState(() => _currentIndex = 3),
        onGoToHistory: _openHistory,
        profile: _profile,
      ),
      // 标签1：食物库
      FoodLibraryScreen(
        foods: _foods,
        onFoodsChanged: _onFoodsChanged,
      ),
      // 标签2：配餐
      MealPlannerScreen(
        foods: _foods,
        profile: _profile,
      ),
      // 标签3：循环
      CycleScreen(
        cycles: _cycles,
        templates: _templates,
        profile: _profile,
        onCyclesChanged: _onCyclesChanged,
      ),
      // 标签4：个人
      ProfileScreen(
        profile: _profile,
        onProfileChanged: _onProfileChanged,
        foods: _foods,
        templates: _templates,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitPlate',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          if (_currentIndex == 4)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存个人资料',
              onPressed: () {
                _onProfileChanged(_profile);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('个人资料已保存'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _addFood,
              icon: const Icon(Icons.add),
              label: const Text('添加食物'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today_outlined), label: '今天'),
          NavigationDestination(
              icon: Icon(Icons.kitchen_outlined), label: '食物库'),
          NavigationDestination(
              icon: Icon(Icons.scale_outlined), label: '配餐'),
          NavigationDestination(
              icon: Icon(Icons.loop_outlined), label: '循环'),
          NavigationDestination(
              icon: Icon(Icons.person_outlined), label: '个人'),
        ],
      ),
    );
  }
}
