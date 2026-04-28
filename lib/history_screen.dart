import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:bmi_calculator/firestore_service.dart';

// ─────────────────────────────────────────────────────────────
// History Screen
// ─────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Statistics filter: 1 = 1 month, 6 = 6 months, 12 = 1 year
  int _statMonths = 1;
  List<Map<String, dynamic>> _statsData = [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    final from = DateTime.now().subtract(Duration(days: _statMonths * 30));
    final data = await FirestoreService.getRecordsForStats(from);
    if (mounted) setState(() { _statsData = data; _statsLoading = false; });
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Underweight': return Colors.blue;
      case 'Normal':      return const Color(0xFF4CAF50);
      case 'Overweight':  return Colors.orange;
      case 'Obese':       return Colors.red;
      default:            return Colors.grey;
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Group docs by calendar-day key "yyyy-MM-dd", return only the last 3 days.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _limitToLast3Days(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> byDay = {};
    for (final doc in docs) {
      final ts = doc.data()['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final dayKey = DateFormat('yyyy-MM-dd').format(ts.toDate());
      // docs are newest-first; first occurrence per day wins
      byDay.putIfAbsent(dayKey, () => doc);
    }
    // Sort keys descending and take first 3
    final sortedKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final top3 = sortedKeys.take(3).toList();
    return top3.map((k) => byDay[k]!).toList();
  }

  // ── Statistics helpers ────────────────────────────────────

  /// Aggregate statsData by month → returns list of {label, bmi, weight, height}
  List<_MonthPoint> _buildMonthPoints() {
    if (_statsData.isEmpty) return [];

    // Group by "yyyy-MM"
    final Map<String, List<Map<String, dynamic>>> byMonth = {};
    for (final rec in _statsData) {
      final ts = rec['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final key = DateFormat('yyyy-MM').format(ts.toDate());
      byMonth.putIfAbsent(key, () => []).add(rec);
    }

    // Sort keys ascending
    final sortedKeys = byMonth.keys.toList()..sort();
    return sortedKeys.map((key) {
      final entries = byMonth[key]!;
      double avgBmi    = entries.map((e) => (e['bmi'] as num).toDouble()).reduce((a, b) => a + b) / entries.length;
      double avgWeight = entries.map((e) => (e['weight'] as num).toDouble()).reduce((a, b) => a + b) / entries.length;
      double avgHeight = entries.map((e) => (e['height'] as num).toDouble()).reduce((a, b) => a + b) / entries.length;
      final label = DateFormat('MMM yy').format(DateFormat('yyyy-MM').parse(key));
      return _MonthPoint(label: label, bmi: avgBmi, weight: avgWeight, height: avgHeight);
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete All',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete All Records'),
                  content: const Text(
                      'Are you sure you want to delete all your BMI history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete All',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await FirestoreService.deleteAllRecords();
                _loadStats();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.hasData ? snapshot.data!.docs : [];
          final displayDocs = _limitToLast3Days(
              allDocs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());

          return CustomScrollView(
            slivers: [
              // ── Section header ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('Recent Records',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Last 3 days',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),

              // ── History list (max 3 entries) ─────────────
              if (displayDocs.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyHistory())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) return const SizedBox(height: 8);
                        final doc = displayDocs[index ~/ 2];
                        return _buildHistoryCard(doc);
                      },
                      childCount: displayDocs.length * 2 - 1,
                    ),
                  ),
                ),

              // ── Statistics section ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('Statistics',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterChips(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatsCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildEmptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No BMI records yet',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Calculate your BMI to save records here',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final bmi        = (data['bmi'] as num).toDouble();
    final weight     = (data['weight'] as num).toDouble();
    final weightUnit = data['weightUnit'] as String? ?? 'kg';
    final height     = (data['height'] as num).toDouble();
    final heightUnit = data['heightUnit'] as String? ?? 'cm';
    final category   = data['category'] as String? ?? '';
    final timestamp  = data['createdAt'] as Timestamp?;
    final date       = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : 'Unknown date';
    final catColor = _categoryColor(category);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        FirestoreService.deleteRecord(doc.id);
        _loadStats();
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // BMI circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: catColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Weight: ${weight.toStringAsFixed(1)} $weightUnit  •  Height: ${height.toStringAsFixed(1)} $heightUnit',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(date,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                onPressed: () {
                  FirestoreService.deleteRecord(doc.id);
                  _loadStats();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const options = [
      (label: '1 Month', months: 1),
      (label: '6 Months', months: 6),
      (label: '1 Year', months: 12),
    ];
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: options.map((opt) {
        final selected = _statMonths == opt.months;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (!selected) {
                setState(() => _statMonths = opt.months);
                _loadStats();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.black : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard() {
    if (_statsLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final points = _buildMonthPoints();

    if (points.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_chart_outlined_rounded,
                  size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Not enough data yet',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                  'Keep calculating your BMI\nto see trends here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return _StatisticsCard(points: points, months: _statMonths);
  }
}

// ─────────────────────────────────────────────────────────────
// Statistics Card — Grouped Bar Chart
// ─────────────────────────────────────────────────────────────
class _StatisticsCard extends StatefulWidget {
  final List<_MonthPoint> points;
  final int months;
  const _StatisticsCard({required this.points, required this.months});

  @override
  State<_StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<_StatisticsCard> {
  int? _touchedGroup;

  static const _bmiColor    = Color(0xFF317eb6);
  static const _weightColor = Color(0xFFFF7043);
  static const _heightColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    final latest   = pts.last;
    final previous = pts.length > 1 ? pts[pts.length - 2] : null;

    final maxBmi    = pts.map((p) => p.bmi).reduce((a, b) => a > b ? a : b);
    final maxWeight = pts.map((p) => p.weight).reduce((a, b) => a > b ? a : b);
    final maxHeight = pts.map((p) => p.height).reduce((a, b) => a > b ? a : b);

    double norm(double val, double max) => max > 0 ? (val / max) * 10 : 0;

    final barGroups = List.generate(pts.length, (i) {
      final p = pts[i];
      final touched = i == _touchedGroup;
      final alpha = touched ? 1.0 : 0.82;
      return BarChartGroupData(
        x: i,
        barsSpace: 3,
        barRods: [
          BarChartRodData(toY: norm(p.bmi, maxBmi),       color: _bmiColor.withValues(alpha: alpha),    width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          BarChartRodData(toY: norm(p.weight, maxWeight), color: _weightColor.withValues(alpha: alpha), width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          BarChartRodData(toY: norm(p.height, maxHeight), color: _heightColor.withValues(alpha: alpha), width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ],
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _legendDot('BMI',    _bmiColor),
            const SizedBox(width: 14),
            _legendDot('Weight', _weightColor),
            const SizedBox(width: 14),
            _legendDot('Height', _heightColor),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4, bottom: 8),
            child: BarChart(BarChartData(
              maxY: 11, minY: 0,
              barTouchData: BarTouchData(
                touchCallback: (event, response) =>
                    setState(() => _touchedGroup = response?.spot?.touchedBarGroupIndex),
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final p = pts[groupIndex];
                    final labels = [
                      'BMI: ${p.bmi.toStringAsFixed(1)}',
                      'Wt: ${p.weight.toStringAsFixed(1)}',
                      'Ht: ${p.height.toStringAsFixed(1)}',
                    ];
                    return BarTooltipItem(labels[rodIndex],
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                  },
                ),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    final i = val.toInt();
                    if (i < 0 || i >= pts.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(pts[i].label,
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    );
                  },
                )),
              ),
              barGroups: barGroups,
            )),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _summaryRow('BMI',    latest.bmi,    previous?.bmi,    _bmiColor,    down: true),
            const SizedBox(height: 10),
            _summaryRow('Weight', latest.weight, previous?.weight, _weightColor, down: true),
            const SizedBox(height: 10),
            _summaryRow('Height', latest.height, previous?.height, _heightColor, down: false),
          ]),
        ),
      ]),
    );
  }

  Widget _legendDot(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ],
  );

  Widget _summaryRow(String label, double latest, double? previous, Color color, {required bool down}) {
    final delta = previous != null ? latest - previous : null;
    final isGood = delta == null ? null : (down ? delta <= 0 : delta >= 0);
    final changeColor = delta == null || delta == 0 ? Colors.grey : (isGood! ? const Color(0xFF4CAF50) : Colors.red);
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      SizedBox(width: 52, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
      Text(latest.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      if (delta != null) ...[
        const SizedBox(width: 10),
        Icon(delta == 0 ? Icons.remove : delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 13, color: changeColor),
        const SizedBox(width: 2),
        Text(delta.abs().toStringAsFixed(1),
            style: TextStyle(fontSize: 12, color: changeColor, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('from ${previous!.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class _MonthPoint {
  final String label;
  final double bmi;
  final double weight;
  final double height;
  const _MonthPoint({required this.label, required this.bmi, required this.weight, required this.height});
}
