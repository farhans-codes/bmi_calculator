import 'package:flutter/material.dart';
import 'package:bmi_calculator/app_theme.dart';
import 'package:bmi_calculator/bmi_calculator_screen.dart';

void main() {
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
