import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmi_calculator/bloc/history_bloc.dart';
import 'package:bmi_calculator/firestore_service.dart';
import 'package:bmi_calculator/profile_screen.dart';

// ─────────────────────────────────────────────────────────────
// History Screen
// ─────────────────────────────────────────────────────────────
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryBloc()..add(const LoadStats()),
      child: const _HistoryScreenBody(),
    );
  }
}

class _HistoryScreenBody extends StatelessWidget {
  const _HistoryScreenBody();

  Color _categoryColor(String category) {
    switch (category) {
      case 'Underweight': return Colors.blue;
      case 'Normal':      return const Color(0xFF4CAF50);
      case 'Overweight':  return Colors.orange;
      case 'Obese':       return Colors.red;
      default:            return Colors.grey;
    }
  }

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
              if (confirmed == true && context.mounted) {
                context.read<HistoryBloc>().add(DeleteAllRecords());
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
                        return _buildHistoryCard(context, doc);
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
                  child: _buildFilterChips(context),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatsCard(context),
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

  Widget _buildHistoryCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
      onDismissed: (_) => context.read<HistoryBloc>().add(DeleteRecord(doc.id)),
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
                onPressed: () => context.read<HistoryBloc>().add(DeleteRecord(doc.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    const options = [
      (label: '1 Month', months: 1),
      (label: '6 Months', months: 6),
      (label: '1 Year', months: 12),
    ];
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (prev, curr) => prev.statMonths != curr.statMonths,
      builder: (context, state) {
        return Row(
          children: options.map((opt) {
            final selected = state.statMonths == opt.months;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (!selected) {
                    context.read<HistoryBloc>().add(ChangeFilter(opt.months));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? primaryColor : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? primaryColor : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state.statsLoading && state.statsData.isEmpty) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final points = state.chartPoints;

        if (points.isEmpty) {
          return Container(
            height: 240,
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

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              StatisticsCard(points: points, months: state.statMonths),
              if (state.statsLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
