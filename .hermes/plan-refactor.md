# FitPlate 代码重构计划

## 代码评审总结

### 问题 1：代码重复（DRY）
- `MealCalculator.calculate()` 计算逻辑 + 结果渲染在 **4 个**地方重复出现
- 模板食物列表渲染（名称、单位、营养值）同上
- `NutritionReference.lookupFactor()` 的"最接近"搜索逻辑有 2 份（getFactor 是旧版，lookupFactor 是新版）

### 问题 2：大型文件（SRP 违反）
| 文件 | 行数 | 问题 |
|------|------|------|
| cycle_screen.dart | 983 | 混合循环列表 + CycleEditor + CycleCard |
| profile_screen.dart | 786 | 混合表单 + 参考表弹窗 + 每日目标卡片 |
| nutrition_reference.dart | 823 | 纯数据（可接受，但建议与逻辑分离）|
| meal_planner_screen.dart | ~450 | 混合食物选择 + 结果渲染 |

### 问题 3：关注点混杂
- `MealCalculator` 和 `FoodAmountFormatter` 在 `models/food.dart` 里（应放在 utils/）
- `MacroReferenceRow` 在 `models/user_profile.dart`（应与 nutrition_reference.dart 一起）
- 业务逻辑与 UI 代码混合

### 问题 4：可变状态模式
- `UserProfile` 是可变对象，主页直接 `widget.profile.height = x` 修改
- `MealTarget` 在 HomeScreen 中作为共享的可变引用传递
- 没有使用不可变状态模式或状态管理方案

### 问题 5：导入/整理问题
- 缺少 const 构造器
- 分类名称为 magic strings（'主食', '蛋白质-纯瘦肉' 等）

## 重构计划（4 个阶段）

### Phase 1: 分离关注点 — 抽取工具类
- 创建 `lib/utils/meal_utils.dart`
  - 从 `models/food.dart` 移动 `MealCalculator`
  - 从 `models/food.dart` 移动 `FoodAmountFormatter`
  - 保留原文件中的 type alias/import
- 创建 `lib/utils/constants.dart`
  - 抽取魔法字符串常量（分类名，子分类名）
- 更新所有 import

### Phase 2: 抽取共享 Widget
- 创建 `lib/widgets/template_result_card.dart`
  - 封装模板食物列表 + 营养摘要的渲染
  - 替换 TodayScreen、TemplateListScreen、MealPlannerScreen 中的重复代码
- 创建 `lib/widgets/nutrient_display.dart`
  - 封装每日目标显示（蛋白质/碳水/卡路里列）
  - 替换 ProfileScreen 中的 _TargetColumn
  - 替换各结果卡片中的营养摘要

### Phase 3: 拆分大文件
- CycleScreen → 拆分为：
  - `screens/cycle_screen.dart`（列表 + 操作）
  - `screens/cycle_editor_screen.dart`（编辑器）
  - `widgets/cycle_card.dart`
- ProfileScreen：
  - 抽取参考表弹窗为独立 widget

### Phase 4: 状态管理改进
- UserProfile 增加 `copyWith()` 方法（已有 copy，改名统一）
- 修复 HomeScreen 中 `_target` 的共享可变引用

## 执行方式
使用 Claude Code 执行每个阶段，每步完成后验证 `dart analyze` 无错误。
