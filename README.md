# BMI Calculator

A simple app to calculate your Body Mass Index (BMI).

## What it does

This app helps you calculate your BMI by entering your weight and height. It supports different units:
- Weight: kg or lb (pounds)
- Height: m (meter), cm (centimeter), or ft + in (feet & inches)

The app will show your BMI number and tell you which category you fall into:
- Underweight (Blue)
- Normal (Green) 
- Overweight (Orange)
- Obese (Red)

## How to use

1. Enter your weight and select the unit (kg or lb)
2. Enter your height and select the unit (m, cm, or ft & in)
3. Click "Calculate BMI"
4. See your result with the category and color

## Files in the project

- main.dart - Starts the app
- app_theme.dart - Handles light and dark themes
- bmi_calculator_screen.dart - The main screen with all the UI
- bmi_utils.dart - Does all the calculations

## BMI Formula and Unit Conversions

The app uses these formulas:

- BMI = weight in kg / (height in meters)²

Unit conversions:
- lb to kg: kg = lb × 0.45359237
- cm to m: m = cm / 100
- feet & inches to m: m = (feet × 12 + inches) × 0.0254

## Category-to-Color Mapping

- Underweight (< 18.5) → Blue
- Normal (18.5 – 24.9) → Green
- Overweight (25.0 – 29.9) → Orange
- Obese (≥ 30.0) → Red

## How to run the app

1. Make sure you have Flutter installed
2. Open this folder in your terminal
3. Run `flutter pub get` to get dependencies
4. Run `flutter run` to start the app

## Screenshots
<img width="434" height="974" alt="image" src="https://github.com/user-attachments/assets/988825c4-cb9f-4376-8258-a4c23d0e7024" />
<img width="465" height="982" alt="image" src="https://github.com/user-attachments/assets/306466aa-7831-4a54-8bc2-78a1288a7ae5" />
<img width="439" height="995" alt="image" src="https://github.com/user-attachments/assets/38cc07a2-a8bd-495f-972b-a2b92d97f85f" />





## Hints for developers

- Uses FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) for decimal inputs
- Rounds display with toStringAsFixed(1) but stores full precision internally
- Conversion functions are small and testable (e.g., cmToMeters, feetInchToMeters, poundsToKg)

## Test cases that work

- 70 kg, 170 cm → BMI ≈ 24.2, Normal (Green)
- 155 lb, 5′7″ → BMI ≈ 24.3, Normal (Green)  
- 95 kg, 165 cm → BMI ≈ 34.9, Obese (Red)

