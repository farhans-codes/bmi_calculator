import 'package:flutter/material.dart';
import 'package:bmi_calculator/app_theme.dart';
import 'package:bmi_calculator/bmi_utils.dart';
import 'package:bmi_calculator/about_screen.dart';
import 'package:bmi_calculator/about_us_screen.dart';
import 'package:bmi_calculator/what_is_bmi_screen.dart';
import 'package:bmi_calculator/privacy_policy_screen.dart';
import 'package:bmi_calculator/auth_service.dart';
import 'package:bmi_calculator/firestore_service.dart';
import 'package:bmi_calculator/profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BMICalculatorScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const BMICalculatorScreen({super.key, required this.onThemeToggle});

  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  bool _weightHasError = false;
  String _weightUnit = 'kg';

  final TextEditingController _heightMeterController = TextEditingController();
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchController = TextEditingController();
  final FocusNode _heightMeterFocusNode = FocusNode();
  final FocusNode _heightCmFocusNode = FocusNode();
  final FocusNode _heightFeetFocusNode = FocusNode();
  bool _heightHasError = false;
  String _heightUnit = 'cm';

  double? _bmi;
  String _category = '';
  Color _categoryColor = Colors.grey;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Listen to auth state
    AuthService.userStream.listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });

    // Weight focus হারালে red border সরাও
    _weightFocusNode.addListener(() {
      if (!_weightFocusNode.hasFocus && _weightHasError) {
        setState(() => _weightHasError = false);
      }
    });
    // Height focus হারালে red border সরাও
    void clearHeightError() {
      if (_heightHasError) setState(() => _heightHasError = false);
    }
    _heightMeterFocusNode.addListener(() {
      if (!_heightMeterFocusNode.hasFocus) clearHeightError();
    });
    _heightCmFocusNode.addListener(() {
      if (!_heightCmFocusNode.hasFocus) clearHeightError();
    });
    _heightFeetFocusNode.addListener(() {
      if (!_heightFeetFocusNode.hasFocus) clearHeightError();
    });
  }

  // খালি field-এ focus করার helper
  void _focusField(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  bool _isHeightEmpty() {
    if (_heightUnit == 'm') return _heightMeterController.text.isEmpty;
    if (_heightUnit == 'cm') return _heightCmController.text.isEmpty;
    return _heightFeetController.text.isEmpty;
  }

  void _focusHeightField() {
    if (_heightUnit == 'm') {
      _focusField(_heightMeterFocusNode);
    } else if (_heightUnit == 'cm') {
      _focusField(_heightCmFocusNode);
    } else {
      _focusField(_heightFeetFocusNode);
    }
  }

  void _calculateBMI() {
    final weightEmpty = _weightController.text.isEmpty;
    final heightEmpty = _isHeightEmpty();

    // দুটোই খালি → weight-এ focus + red border
    if (weightEmpty && heightEmpty) {
      setState(() { _weightHasError = true; _heightHasError = false; });
      _focusField(_weightFocusNode);
      return;
    }

    // শুধু weight খালি → weight-এ focus + red border
    if (weightEmpty) {
      setState(() { _weightHasError = true; _heightHasError = false; });
      _focusField(_weightFocusNode);
      return;
    }

    // শুধু height খালি → height-এ focus + red border
    if (heightEmpty) {
      setState(() { _heightHasError = true; _weightHasError = false; });
      _focusHeightField();
      return;
    }

    // সব ঠিক আছে, keyboard dismiss করো
    FocusScope.of(context).unfocus();

    setState(() {
      _bmi = null;
      _category = '';
      _categoryColor = Colors.grey;
    });

    double weight;
    try {
      weight = double.parse(_weightController.text);
      if (weight <= 0) {
        _showError('Weight must be greater than 0');
        return;
      }
    } catch (e) {
      _showError('Please enter a valid weight');
      return;
    }

    double heightInMeters;
    try {
      if (_heightUnit == 'm') {
        double meters = double.parse(_heightMeterController.text);
        if (meters <= 0) {
          _showError('Height must be greater than 0');
          return;
        }
        heightInMeters = meters;
      } else if (_heightUnit == 'cm') {
        double cm = double.parse(_heightCmController.text);
        if (cm <= 0) {
          _showError('Height must be greater than 0');
          return;
        }
        heightInMeters = BMIUtils.cmToMeters(cm);
      } else {
        String feetText = _heightFeetController.text;
        String inchText = _heightInchController.text;

        double feet = feetText.isNotEmpty ? double.parse(feetText) : 0;
        double inches = inchText.isNotEmpty ? double.parse(inchText) : 0;

        if (feet < 0 || inches < 0) {
          _showError('Height values must be positive');
          return;
        }

        if (inches >= 12) {
          final normalized = BMIUtils.normalizeFeetInches(feet, inches);
          feet = normalized['feet']!;
          inches = normalized['inches']!;
          _heightFeetController.text = feet.toString();
          _heightInchController.text = inches.toStringAsFixed(1);
        }

        if (feet == 0 && inches == 0) {
          _showError('Height must be greater than 0');
          return;
        }

        heightInMeters = BMIUtils.feetInchToMeters(feet, inches);
      }
    } catch (e) {
      _showError('Please enter valid height values');
      return;
    }

    double weightInKg = _weightUnit == 'kg'
        ? weight
        : BMIUtils.poundsToKg(weight);

    setState(() {
      _bmi = BMIUtils.calculateBMI(weightInKg, heightInMeters);

      _category = BMIUtils.getCategory(_bmi!);

      switch (_category) {
        case 'Underweight':
          _categoryColor = Colors.blue;
          break;
        case 'Normal':
          _categoryColor = Colors.green;
          break;
        case 'Overweight':
          _categoryColor = Colors.orange;
          break;
        case 'Obese':
          _categoryColor = Colors.red;
          break;
        default:
          _categoryColor = Colors.grey;
      }
    });

    // Save to Firestore if user is logged in
    if (_currentUser != null) {
      double displayHeight;
      String displayHeightUnit;
      if (_heightUnit == 'm') {
        displayHeight = double.tryParse(_heightMeterController.text) ?? 0;
        displayHeightUnit = 'm';
      } else if (_heightUnit == 'cm') {
        displayHeight = double.tryParse(_heightCmController.text) ?? 0;
        displayHeightUnit = 'cm';
      } else {
        displayHeight = double.tryParse(_heightFeetController.text) ?? 0;
        displayHeightUnit = 'ft';
      }
      FirestoreService.saveRecord(
        bmi: _bmi!,
        weight: weight,
        weightUnit: _weightUnit,
        height: displayHeight,
        heightUnit: displayHeightUnit,
        category: _category,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearAll() {
    setState(() {
      _weightController.clear();
      _heightMeterController.clear();
      _heightCmController.clear();
      _heightFeetController.clear();
      _heightInchController.clear();
      _bmi = null;
      _category = '';
      _categoryColor = Colors.grey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // ── Scrollable menu area ──────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurfaceColor
                          : Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SvgPicture.asset(
                            'assets/svgviewer-output.svg',
                            width: 64,
                            height: 64,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BMI Calculator',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.primaryColor
                                : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.primaryColor.withValues(alpha: 0.7)
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: SvgPicture.asset('assets/home.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.white, BlendMode.srcIn)),
                    title: const Text('Home'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.menu_book_rounded, color: Theme.of(context).iconTheme.color ?? Colors.white),
                    title: const Text('What is BMI?'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WhatIsBMIScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset('assets/about.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.white, BlendMode.srcIn)),
                    title: const Text('About App'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: SvgPicture.asset('assets/privacy.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.white, BlendMode.srcIn)),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset('assets/share.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.white, BlendMode.srcIn)),
                    title: const Text('Share App'),
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(
                        'Check out BMI Calculator - a simple app to calculate your Body Mass Index!\n\nhttps://play.google.com/store/apps/details?id=com.farhan.bmicalculator',
                        subject: 'BMI Calculator App',
                      );
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset('assets/star.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.white, BlendMode.srcIn)),
                    title: const Text('Rate Us'),
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.farhan.bmicalculator',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.group_outlined, color: Theme.of(context).iconTheme.color ?? Colors.white),
                    title: const Text('About Us'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Sign In / User info pinned at the very bottom ──
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _currentUser != null
                    // Logged in → tap goes to ProfileScreen
                    ? ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: _currentUser!.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser!.photoURL == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: const Text(
                          'Profile',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _currentUser!.email ?? '',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                      )
                    : ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFE8F0E9),
                            border: Border.all(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: SvgPicture.asset(
                            'assets/user_avatar.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        title: const Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          final user = await AuthService.signInWithGoogle();
                          if (user != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
                            );
                          }
                        },
                      ),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgPicture.asset(
              'assets/menu.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).iconTheme.color ?? Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
                FocusScope.of(context).unfocus();
                Scaffold.of(context).openDrawer();
              },
          ),
        ),
        title: const Text(
          'BMI Calculator',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/sun.svg'
                  : 'assets/moon.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).iconTheme.color ?? Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weight',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _weightController,
                      focusNode: _weightFocusNode,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) {
                        if (_weightHasError) setState(() => _weightHasError = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter weight',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        enabledBorder: _weightHasError
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              )
                            : OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                        focusedBorder: _weightHasError
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              )
                            : OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'kg', label: Text('kg')),
                        ButtonSegment(value: 'lb', label: Text('lb')),
                      ],
                      selected: {_weightUnit},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _weightUnit = newSelection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Height',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cm', label: Text('cm')),
                ButtonSegment(value: 'm', label: Text('m')),
                ButtonSegment(value: 'ft', label: Text('ft & in')),
              ],
              selected: {_heightUnit},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _heightUnit = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 10),
            if (_heightUnit == 'm') ...[
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _heightMeterController,
                  focusNode: _heightMeterFocusNode,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) {
                    if (_heightHasError) setState(() => _heightHasError = false);
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter height in meters',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: _heightHasError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          )
                        : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    focusedBorder: _heightHasError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          )
                        : OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ] else if (_heightUnit == 'cm') ...[
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _heightCmController,
                  focusNode: _heightCmFocusNode,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) {
                    if (_heightHasError) setState(() => _heightHasError = false);
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter height in centimeters',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: _heightHasError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          )
                        : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    focusedBorder: _heightHasError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          )
                        : OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _heightFeetController,
                        focusNode: _heightFeetFocusNode,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) {
                          if (_heightHasError) setState(() => _heightHasError = false);
                        },
                        decoration: InputDecoration(
                          labelText: 'Feet',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          enabledBorder: _heightHasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                )
                              : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          focusedBorder: _heightHasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                )
                              : OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _heightInchController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Inches',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _calculateBMI,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Calculate BMI',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Clear All'),
            ),
            const SizedBox(height: 30),

            if (_bmi != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _categoryColor, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your BMI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _bmi!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Category Ranges:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text('Underweight: < 18.5'),
                    const Text('Normal: 18.5 - 24.9'),
                    const Text('Overweight: 25.0 - 29.9'),
                    const Text('Obese: ≥ 30.0'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightFocusNode.dispose();
    _heightMeterController.dispose();
    _heightMeterFocusNode.dispose();
    _heightCmController.dispose();
    _heightCmFocusNode.dispose();
    _heightFeetController.dispose();
    _heightFeetFocusNode.dispose();
    _heightInchController.dispose();
    super.dispose();
  }
}
