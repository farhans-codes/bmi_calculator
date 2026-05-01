import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmi_calculator/app_theme.dart';
import 'package:bmi_calculator/about_screen.dart';
import 'package:bmi_calculator/about_us_screen.dart';
import 'package:bmi_calculator/what_is_bmi_screen.dart';
import 'package:bmi_calculator/privacy_policy_screen.dart';
import 'package:bmi_calculator/profile_screen.dart';
import 'package:bmi_calculator/bloc/theme_cubit.dart';
import 'package:bmi_calculator/bloc/auth_cubit.dart';
import 'package:bmi_calculator/bloc/bmi_calculator_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BMICalculatorScreen extends StatelessWidget {
  const BMICalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BmiCalculatorBloc(),
      child: const _BMICalculatorScreenBody(),
    );
  }
}

class _BMICalculatorScreenBody extends StatefulWidget {
  const _BMICalculatorScreenBody();

  @override
  State<_BMICalculatorScreenBody> createState() => _BMICalculatorScreenBodyState();
}

class _BMICalculatorScreenBodyState extends State<_BMICalculatorScreenBody> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();

  final TextEditingController _heightMeterController = TextEditingController();
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchController = TextEditingController();
  final FocusNode _heightMeterFocusNode = FocusNode();
  final FocusNode _heightCmFocusNode = FocusNode();
  final FocusNode _heightFeetFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Weight focus হারালে red border সরাও
    _weightFocusNode.addListener(() {
      if (!_weightFocusNode.hasFocus) {
        context.read<BmiCalculatorBloc>().add(ClearWeightError());
      }
    });
    // Height focus হারালে red border সরাও
    void clearHeightError() {
      context.read<BmiCalculatorBloc>().add(ClearHeightError());
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

  void _focusHeightField(String heightUnit) {
    if (heightUnit == 'm') {
      _focusField(_heightMeterFocusNode);
    } else if (heightUnit == 'cm') {
      _focusField(_heightCmFocusNode);
    } else {
      _focusField(_heightFeetFocusNode);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _dispatchCalculate() {
    final authState = context.read<AuthCubit>().state;
    context.read<BmiCalculatorBloc>().add(CalculateBmi(
      weightText: _weightController.text,
      heightMeterText: _heightMeterController.text,
      heightCmText: _heightCmController.text,
      heightFeetText: _heightFeetController.text,
      heightInchText: _heightInchController.text,
      isLoggedIn: authState.user != null,
    ));
  }

  void _dispatchClear() {
    _weightController.clear();
    _heightMeterController.clear();
    _heightCmController.clear();
    _heightFeetController.clear();
    _heightInchController.clear();
    context.read<BmiCalculatorBloc>().add(ClearAll());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BmiCalculatorBloc, BmiCalculatorState>(
      listenWhen: (prev, curr) =>
          prev.focusRequest != curr.focusRequest ||
          prev.errorMessage != curr.errorMessage ||
          prev.normalizedHeight != curr.normalizedHeight,
      listener: (context, state) {
        // Handle focus requests
        if (state.focusRequest == 'weight') {
          _focusField(_weightFocusNode);
          context.read<BmiCalculatorBloc>().add(ClearFocusRequest());
        } else if (state.focusRequest == 'height') {
          _focusHeightField(state.heightUnit);
          context.read<BmiCalculatorBloc>().add(ClearFocusRequest());
        } else if (state.focusRequest == 'unfocus') {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          context.read<BmiCalculatorBloc>().add(ClearFocusRequest());
        }

        // Handle error messages
        if (state.errorMessage != null) {
          _showError(state.errorMessage!);
        }

        // Handle normalized height write-back
        if (state.normalizedHeight != null) {
          _heightFeetController.text = state.normalizedHeight!['feet'] ?? '';
          _heightInchController.text = state.normalizedHeight!['inches'] ?? '';
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) {
        FocusManager.instance.primaryFocus?.unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      drawer: _buildDrawer(context),
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
              FocusManager.instance.primaryFocus?.unfocus();
              SystemChannels.textInput.invokeMethod('TextInput.hide');
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
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<BmiCalculatorBloc, BmiCalculatorState>(
            builder: (context, state) {
              return Column(
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (_) {
                              if (state.weightHasError) {
                                context.read<BmiCalculatorBloc>().add(ClearWeightError());
                              }
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
                              enabledBorder: state.weightHasError
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    )
                                  : OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                              focusedBorder: state.weightHasError
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
                            selected: {state.weightUnit},
                            onSelectionChanged: (Set<String> newSelection) {
                              context.read<BmiCalculatorBloc>().add(
                                    WeightUnitChanged(newSelection.first),
                                  );
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
                    selected: {state.heightUnit},
                    onSelectionChanged: (Set<String> newSelection) {
                      context.read<BmiCalculatorBloc>().add(
                            HeightUnitChanged(newSelection.first),
                          );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (state.heightUnit == 'm') ...[
                    SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _heightMeterController,
                        focusNode: _heightMeterFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) {
                          if (state.heightHasError) {
                            context.read<BmiCalculatorBloc>().add(ClearHeightError());
                          }
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
                          enabledBorder: state.heightHasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                )
                              : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          focusedBorder: state.heightHasError
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
                  ] else if (state.heightUnit == 'cm') ...[
                    SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _heightCmController,
                        focusNode: _heightCmFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) {
                          if (state.heightHasError) {
                            context.read<BmiCalculatorBloc>().add(ClearHeightError());
                          }
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
                          enabledBorder: state.heightHasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                )
                              : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          focusedBorder: state.heightHasError
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
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (_) {
                                if (state.heightHasError) {
                                  context.read<BmiCalculatorBloc>().add(ClearHeightError());
                                }
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
                                enabledBorder: state.heightHasError
                                    ? OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      )
                                    : OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                focusedBorder: state.heightHasError
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
                              keyboardType: const TextInputType.numberWithOptions(
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
                    onPressed: _dispatchCalculate,
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
                    onPressed: _dispatchClear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(height: 30),

                  if (state.bmi != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: state.categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: state.categoryColor, width: 2),
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
                            state.bmi!.toStringAsFixed(1),
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
                              color: state.categoryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              state.category,
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = authState.user;
        return Drawer(
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
                  child: currentUser != null
                      // Logged in → tap goes to ProfileScreen
                      ? ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: currentUser.photoURL != null
                                ? NetworkImage(currentUser.photoURL!)
                                : null,
                            child: currentUser.photoURL == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: const Text(
                            'Profile',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            currentUser.email ?? '',
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
                            await context.read<AuthCubit>().signInWithGoogle();
                            if (context.mounted) {
                              final user = context.read<AuthCubit>().state.user;
                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ProfileScreen()),
                                );
                              }
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
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
