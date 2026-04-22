import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bmi_calculator/app_theme.dart';

class WhatIsBMIScreen extends StatelessWidget {
  const WhatIsBMIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final textColor = isDark ? Colors.grey[100]! : Colors.grey[900]!;
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What is BMI?'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Understanding BMI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Body Mass Index (BMI) is a simple measurement that uses your height and weight to estimate whether you are at a healthy weight.',
                    style: TextStyle(fontSize: 16, color: subtextColor, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'BMI Formula',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BMI = Weight (kg) / Height² (m²)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BMI Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryBar('Underweight', '< 18.5', Colors.blue, 0.3),
                  const SizedBox(height: 10),
                  _buildCategoryBar('Normal', '18.5 - 24.9', Colors.green, 0.5),
                  const SizedBox(height: 10),
                  _buildCategoryBar('Overweight', '25.0 - 29.9', Colors.orange, 0.7),
                  const SizedBox(height: 10),
                  _buildCategoryBar('Obese', '≥ 30.0', Colors.red, 0.9),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BMI Distribution',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Global adult population by BMI category',
                    style: TextStyle(fontSize: 14, color: subtextColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: 9,
                            title: '9%',
                            color: Colors.blue,
                            radius: 55,
                            titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 39,
                            title: '39%',
                            color: Colors.green,
                            radius: 55,
                            titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 39,
                            title: '39%',
                            color: Colors.orange,
                            radius: 55,
                            titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 13,
                            title: '13%',
                            color: Colors.red,
                            radius: 55,
                            titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendItem('Underweight', Colors.blue),
                      _legendItem('Normal', Colors.green),
                      _legendItem('Overweight', Colors.orange),
                      _legendItem('Obese', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BMI Scale Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BMI ranges and their health risk levels',
                    style: TextStyle(fontSize: 14, color: subtextColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 40,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const titles = ['Under\nweight', 'Normal', 'Over\nweight', 'Obese'];
                                if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      titles[value.toInt()],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: subtextColor),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              reservedSize: 40,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, 18.5, Colors.blue),
                          _makeBarGroup(1, 24.9, Colors.green),
                          _makeBarGroup(2, 29.9, Colors.orange),
                          _makeBarGroup(3, 35, Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Risks by BMI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRiskTile(
                    Icons.arrow_downward_rounded,
                    'Underweight',
                    'Nutritional deficiency, weakened immune system, bone loss, anemia',
                    Colors.blue,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRiskTile(
                    Icons.check_circle_outline,
                    'Normal Weight',
                    'Lowest risk of weight-related health issues. Maintain with balanced diet and exercise.',
                    Colors.green,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRiskTile(
                    Icons.warning_amber_rounded,
                    'Overweight',
                    'Increased risk of heart disease, high blood pressure, type 2 diabetes, and sleep apnea',
                    Colors.orange,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRiskTile(
                    Icons.dangerous_outlined,
                    'Obese',
                    'High risk of cardiovascular disease, stroke, certain cancers, and reduced life expectancy',
                    Colors.red,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limitations of BMI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLimitationItem(
                    Icons.fitness_center,
                    'Muscle Mass',
                    'BMI doesn\'t distinguish between muscle and fat. Athletes may have a high BMI but low body fat.',
                    isDark,
                  ),
                  _buildLimitationItem(
                    Icons.elderly,
                    'Age & Gender',
                    'BMI doesn\'t account for age-related muscle loss or differences between men and women.',
                    isDark,
                  ),
                  _buildLimitationItem(
                    Icons.people,
                    'Ethnicity',
                    'Health risks at different BMI levels can vary across ethnic groups.',
                    isDark,
                  ),
                  _buildLimitationItem(
                    Icons.child_care,
                    'Children',
                    'BMI for children uses age- and gender-specific percentile charts, not the same adult scale.',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Color color, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCategoryBar(String label, String range, Color color, double fill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
            Text(range, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  static Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskTile(IconData icon, String title, String desc, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationItem(IconData icon, String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.grey[100] : Colors.grey[900])),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
