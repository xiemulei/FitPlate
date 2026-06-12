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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Food> _foods = [];
  final MealTarget _target = MealTarget(protein: 35.0, carbs: 45.0);
  List<SelectedFood> _selected = [];
  List<MealTemplate> _templates = [];
  List<TrainingCycle> _cycles = [];
  UserProfile _profile = UserProfile();

  @override
  void initState() {
    super.initState();
    _loadData();
    _foods = List.from(PresetFoods.all);
  }

  Future<void> _loadData() async {
    final t = await StorageService.loadTemplates();
    final pr = await StorageService.loadProfile();
    final c = await StorageService.loadCycles();
    setState(() { _templates = t; _cycles = c; _profile = pr; });
  }

  Future<void> _onProfileChanged(UserProfile p) async {
    setState(() => _profile = p);
    await StorageService.saveProfile(p);
  }

  Future<void> _saveTemplates() async {
    await StorageService.saveTemplates(_templates);
  }

  Future<void> _onCyclesChanged(List<TrainingCycle> cycles) async {
    setState(() => _cycles = cycles);
    await StorageService.saveCycles(cycles);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        cycles: _cycles,
        templates: _templates,
        foods: _foods,
        onGoToCycle: () => setState(() => _currentIndex = 3),
      ),
      FoodLibraryScreen(
        foods: _foods,
        onFoodsChanged: (f) => setState(() => _foods = f),
      ),
      MealPlannerScreen(
        foods: _foods,
        target: _target,
        selected: _selected,
        onTargetChanged: (t) => setState(() { _target.protein = t.protein; _target.carbs = t.carbs; }),
        onSelectedChanged: (s) => setState(() => _selected = s),
        templates: _templates,
        onSaveTemplate: (t) async {
          setState(() => _templates.add(t));
          await _saveTemplates();
        },
      ),
      CycleScreen(
        cycles: _cycles,
        templates: _templates,
        onCyclesChanged: _onCyclesChanged,
      ),
      ProfileScreen(
        profile: _profile,
        onProfileChanged: _onProfileChanged,
        foods: _foods,
        templates: _templates,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitPlate', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<Food>(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodDetailScreen()),
                );
                if (result != null) {
                  _foods.add(result);
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('添加食物'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: '今天'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), label: '食物库'),
          NavigationDestination(icon: Icon(Icons.scale_outlined), label: '配餐'),
          NavigationDestination(icon: Icon(Icons.loop_outlined), label: '循环'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: '个人'),
        ],
      ),
    );
  }
}
