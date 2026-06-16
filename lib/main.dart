import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/nutrition_reference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NutritionReference.load();
  runApp(const MacroMealApp());
}

class MacroMealApp extends StatelessWidget {
  const MacroMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF06B6D4),
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
