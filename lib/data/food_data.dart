import '../models/food.dart';
import '../utils/constants.dart';

/// 预设食物库 —— 常见食物的营养成分（每100g可食部）
class PresetFoods {
  PresetFoods._();

  /// 所有预设食物列表
  static List<Food> get all => _all;

  /// 按分类分组（用于页面展示）
  static Map<String, List<Food>> get grouped {
    final map = <String, List<Food>>{};
    for (final f in _all) {
      map.putIfAbsent(f.category, () => []).add(f);
    }
    return map;
  }

  /// 按子分类分组（主食专用）
  static Map<String, List<Food>> get bySubcategory {
    final map = <String, List<Food>>{};
    for (final f in _all) {
      if (f.subcategory != null && f.subcategory!.isNotEmpty) {
        map.putIfAbsent(f.subcategory!, () => []).add(f);
      } else {
        map.putIfAbsent(f.category, () => []).add(f);
      }
    }
    return map;
  }

  /// 获取所有可选的分类名称
  static const List<String> categories = [
    FoodCategory.staple,
    FoodCategory.leanProtein,
    FoodCategory.proteinPowder,
  ];

  /// 主食子分类
  static const Map<String, List<String>> subcategories = {
    FoodCategory.staple: [
      StapleSubcategory.ricePorridge,
      StapleSubcategory.noodles,
      StapleSubcategory.grains,
      StapleSubcategory.bread,
      StapleSubcategory.rootTubers,
    ],
  };

  /// 可选的子分类（用于新增食物时的选择器）
  static List<String> subcategoriesOf(String category) =>
      subcategories[category] ?? [];

  // ═══════════════════════════════════════
  //  主食 · 米饭粥类
  // ═══════════════════════════════════════
  static final _riceGroup = [
    Food(
      id: 'staple_rice_white',
      name: '白米饭',
      proteinPer100G: 2.6,
      carbsPer100G: 25.9,
      category: '主食',
      subcategory: '米饭粥类',
    ),
    Food(
      id: 'staple_rice_brown',
      name: '糙米饭',
      proteinPer100G: 3.0,
      carbsPer100G: 25.0,
      category: '主食',
      subcategory: '米饭粥类',
    ),
    Food(
      id: 'staple_rice_porridge',
      name: '白粥',
      proteinPer100G: 1.1,
      carbsPer100G: 9.7,
      category: '主食',
      subcategory: '米饭粥类',
    ),
    Food(
      id: 'staple_millet_porridge',
      name: '小米粥',
      proteinPer100G: 1.4,
      carbsPer100G: 8.4,
      category: '主食',
      subcategory: '米饭粥类',
    ),
    Food(
      id: 'staple_black_rice',
      name: '黑米饭',
      proteinPer100G: 3.2,
      carbsPer100G: 24.0,
      category: '主食',
      subcategory: '米饭粥类',
    ),
    Food(
      id: 'staple_rice_egg_fried',
      name: '蛋炒饭',
      proteinPer100G: 5.0,
      carbsPer100G: 28.0,
      category: '主食',
      subcategory: '米饭粥类',
    ),
  ];

  // ═══════════════════════════════════════
  //  主食 · 面食类
  // ═══════════════════════════════════════
  static final _noodleGroup = [
    Food(
      id: 'staple_noodle_white',
      name: '白面条（煮）',
      proteinPer100G: 2.7,
      carbsPer100G: 25.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_noodle_wholewheat',
      name: '全麦面条（煮）',
      proteinPer100G: 4.0,
      carbsPer100G: 23.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_steamed_bun',
      name: '馒头',
      proteinPer100G: 7.0,
      carbsPer100G: 45.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_steamed_bun_ww',
      name: '全麦馒头',
      proteinPer100G: 8.5,
      carbsPer100G: 40.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_dumpling_pork',
      name: '饺子（猪肉）',
      proteinPer100G: 7.5,
      carbsPer100G: 28.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_wonton',
      name: '馄饨',
      proteinPer100G: 6.0,
      carbsPer100G: 22.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_baozi_pork',
      name: '肉包子',
      proteinPer100G: 8.0,
      carbsPer100G: 30.0,
      category: '主食',
      subcategory: '面食类',
    ),
    Food(
      id: 'staple_noodle_rice_vermicelli',
      name: '米线（煮）',
      proteinPer100G: 1.5,
      carbsPer100G: 22.0,
      category: '主食',
      subcategory: '面食类',
    ),
  ];

  // ═══════════════════════════════════════
  //  主食 · 杂粮类
  // ═══════════════════════════════════════
  static final _grainGroup = [
    Food(
      id: 'staple_oatmeal_cooked',
      name: '燕麦片（煮）',
      proteinPer100G: 3.0,
      carbsPer100G: 12.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_oatmeal_dry',
      name: '燕麦片（干）',
      proteinPer100G: 13.5,
      carbsPer100G: 66.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_quinoa',
      name: '藜麦（熟）',
      proteinPer100G: 4.4,
      carbsPer100G: 21.3,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_buckwheat_noodle',
      name: '荞麦面（熟）',
      proteinPer100G: 4.5,
      carbsPer100G: 21.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_corn',
      name: '玉米（熟）',
      proteinPer100G: 4.0,
      carbsPer100G: 22.8,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_sweet_potato',
      name: '红薯（熟）',
      proteinPer100G: 1.6,
      carbsPer100G: 23.6,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_purple_potato',
      name: '紫薯（熟）',
      proteinPer100G: 1.8,
      carbsPer100G: 25.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_oats_rice',
      name: '燕麦米（饭）',
      proteinPer100G: 3.5,
      carbsPer100G: 22.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
    Food(
      id: 'staple_buckwheat_rice',
      name: '荞麦饭',
      proteinPer100G: 4.0,
      carbsPer100G: 20.0,
      category: '主食',
      subcategory: '杂粮类',
    ),
  ];

  // ═══════════════════════════════════════
  //  主食 · 面包类
  // ═══════════════════════════════════════
  static final _breadGroup = [
    Food(
      id: 'staple_bread_ww',
      name: '全麦面包',
      proteinPer100G: 9.0,
      carbsPer100G: 45.0,
      category: '主食',
      subcategory: '面包类',
    ),
    Food(
      id: 'staple_bread_white',
      name: '白吐司',
      proteinPer100G: 8.0,
      carbsPer100G: 48.0,
      category: '主食',
      subcategory: '面包类',
    ),
    Food(
      id: 'staple_bagel',
      name: '贝果',
      proteinPer100G: 10.0,
      carbsPer100G: 50.0,
      category: '主食',
      subcategory: '面包类',
    ),
    Food(
      id: 'staple_english_muffin',
      name: '英式麦芬',
      proteinPer100G: 8.0,
      carbsPer100G: 42.0,
      category: '主食',
      subcategory: '面包类',
    ),
    Food(
      id: 'staple_naan_bread',
      name: '馕',
      proteinPer100G: 8.5,
      carbsPer100G: 46.0,
      category: '主食',
      subcategory: '面包类',
    ),
  ];

  // ═══════════════════════════════════════
  //  主食 · 根茎类
  // ═══════════════════════════════════════
  static final _rootGroup = [
    Food(
      id: 'staple_potato',
      name: '土豆（熟）',
      proteinPer100G: 2.0,
      carbsPer100G: 17.5,
      category: '主食',
      subcategory: '根茎类',
    ),
    Food(
      id: 'staple_taro',
      name: '芋头（熟）',
      proteinPer100G: 2.2,
      carbsPer100G: 18.5,
      category: '主食',
      subcategory: '根茎类',
    ),
    Food(
      id: 'staple_yam',
      name: '山药（熟）',
      proteinPer100G: 2.0,
      carbsPer100G: 20.0,
      category: '主食',
      subcategory: '根茎类',
    ),
    Food(
      id: 'staple_pumpkin',
      name: '南瓜（熟）',
      proteinPer100G: 1.0,
      carbsPer100G: 5.0,
      category: '主食',
      subcategory: '根茎类',
    ),
  ];

  // ═══════════════════════════════════════
  //  蛋白质 · 纯瘦肉
  // ═══════════════════════════════════════
  static final _leanMeatGroup = [
    Food(
      id: 'protein_chicken_breast',
      name: '鸡胸肉',
      proteinPer100G: 24.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_beef_lean',
      name: '瘦牛肉',
      proteinPer100G: 26.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_pork_tenderloin',
      name: '猪里脊',
      proteinPer100G: 22.0,
      carbsPer100G: 0.5,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_beef_shank',
      name: '牛腱子',
      proteinPer100G: 25.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_chicken_thigh_skinless',
      name: '去皮鸡腿肉',
      proteinPer100G: 20.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_lamb_lean',
      name: '瘦羊肉',
      proteinPer100G: 22.0,
      carbsPer100G: 0.2,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_pork_ham',
      name: '火腿（瘦）',
      proteinPer100G: 18.0,
      carbsPer100G: 1.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_bass',
      name: '鲈鱼',
      proteinPer100G: 18.6,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_salmon',
      name: '三文鱼',
      proteinPer100G: 22.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_cod',
      name: '鳕鱼',
      proteinPer100G: 20.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_shrimp',
      name: '虾仁',
      proteinPer100G: 20.0,
      carbsPer100G: 0.5,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_tuna_canned',
      name: '金枪鱼（水浸）',
      proteinPer100G: 25.0,
      carbsPer100G: 0.1,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_egg_whole',
      name: '鸡蛋（全蛋）',
      unit: FoodUnit.piece,
      gramsPerUnit: 50,
      proteinPer100G: 13.0,
      carbsPer100G: 1.5,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_egg_white',
      name: '蛋白',
      unit: FoodUnit.piece,
      gramsPerUnit: 35,
      proteinPer100G: 11.0,
      carbsPer100G: 1.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_tofu_firm',
      name: '北豆腐（硬）',
      proteinPer100G: 8.0,
      carbsPer100G: 2.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_tofu_soft',
      name: '南豆腐（软）',
      proteinPer100G: 5.0,
      carbsPer100G: 2.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_skim_milk',
      name: '脱脂牛奶',
      proteinPer100G: 3.4,
      carbsPer100G: 5.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_greek_yogurt',
      name: '希腊酸奶',
      proteinPer100G: 10.0,
      carbsPer100G: 4.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_cottage_cheese',
      name: '茅屋芝士',
      proteinPer100G: 11.0,
      carbsPer100G: 3.0,
      category: '蛋白质-纯瘦肉',
    ),
    Food(
      id: 'protein_soy_milk',
      name: '无糖豆浆',
      proteinPer100G: 3.5,
      carbsPer100G: 1.5,
      category: '蛋白质-纯瘦肉',
    ),
  ];

  // ═══════════════════════════════════════
  //  蛋白质 · 蛋白粉
  // ═══════════════════════════════════════
  static final _proteinPowderGroup = [
    Food(
      id: 'protein_whey_concentrate',
      name: '浓缩乳清蛋白粉',
      proteinPer100G: 80.0,
      carbsPer100G: 5.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_whey_isolate',
      name: '分离乳清蛋白粉',
      proteinPer100G: 90.0,
      carbsPer100G: 1.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_whey_hydrolyzed',
      name: '水解乳清蛋白粉',
      proteinPer100G: 88.0,
      carbsPer100G: 2.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_casein',
      name: '酪蛋白粉',
      proteinPer100G: 75.0,
      carbsPer100G: 4.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_soy_isolate',
      name: '分离大豆蛋白粉',
      proteinPer100G: 85.0,
      carbsPer100G: 3.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_pea_isolate',
      name: '豌豆蛋白粉',
      proteinPer100G: 80.0,
      carbsPer100G: 4.0,
      category: '蛋白质-蛋白粉',
    ),
    Food(
      id: 'protein_mass_gainer',
      name: '增肌粉',
      proteinPer100G: 35.0,
      carbsPer100G: 55.0,
      category: '蛋白质-蛋白粉',
    ),
  ];

  /// 完整列表
  static final List<Food> _all = [
    ..._riceGroup,
    ..._noodleGroup,
    ..._grainGroup,
    ..._breadGroup,
    ..._rootGroup,
    ..._leanMeatGroup,
    ..._proteinPowderGroup,
  ];
}
