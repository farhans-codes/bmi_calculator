import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bmi_calculator/app_theme.dart';
import 'package:bmi_calculator/bmi_calculator_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Splash screen 1 second show korbe
  await Future.delayed(const Duration(milliseconds: 1000));

  FlutterNativeSplash.remove();
  runApp(const BMICalculatorApp());
}

class BMICalculatorApp extends StatefulWidget {
  const BMICalculatorApp({super.key});

  @override
  State<BMICalculatorApp> createState() => _BMICalculatorAppState();
}

class _BMICalculatorAppState extends State<BMICalculatorApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: BMICalculatorScreen(onThemeToggle: _toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}
