import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bmi_calculator/firestore_service.dart';

// ─── Events ─────────────────────────────────────────────────
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadStats extends HistoryEvent {
  final bool silent;
  const LoadStats({this.silent = false});
  @override
  List<Object?> get props => [silent];
}

class ChangeFilter extends HistoryEvent {
  final int months;
  const ChangeFilter(this.months);
  @override
  List<Object?> get props => [months];
}

class DeleteRecord extends HistoryEvent {
  final String docId;
  const DeleteRecord(this.docId);
  @override
  List<Object?> get props => [docId];
}

class DeleteAllRecords extends HistoryEvent {}

// ─── State ──────────────────────────────────────────────────
class HistoryState extends Equatable {
  final int statMonths;
  final List<Map<String, dynamic>> statsData;
  final bool statsLoading;

  const HistoryState({
    this.statMonths = 1,
    this.statsData = const [],
    this.statsLoading = true,
  });

  HistoryState copyWith({
    int? statMonths,
    List<Map<String, dynamic>>? statsData,
    bool? statsLoading,
  }) =>
      HistoryState(
        statMonths: statMonths ?? this.statMonths,
        statsData: statsData ?? this.statsData,
        statsLoading: statsLoading ?? this.statsLoading,
      );

  // ── Chart point generation ──────────────────────────────
  List<ChartPoint> get chartPoints {
    if (statsData.isEmpty) return [];
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final rec in statsData) {
      final ts = rec['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final key = statMonths == 1
          ? DateFormat('yyyy-MM-dd').format(date)
          : DateFormat('yyyy-MM').format(date);
      grouped.putIfAbsent(key, () => []).add(rec);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((key) {
      final entries = grouped[key]!;
      double avg(List<double> vals) =>
          vals.reduce((a, b) => a + b) / vals.length;

      String label;
      if (statMonths == 1) {
        label = DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(key));
      } else {
        label = DateFormat('MMM yy').format(DateFormat('yyyy-MM').parse(key));
      }

      return ChartPoint(
        label: label,
        bmi: avg(entries.map((e) => (e['bmi'] as num).toDouble()).toList()),
        weight:
            avg(entries.map((e) => (e['weight'] as num).toDouble()).toList()),
        height:
            avg(entries.map((e) => (e['height'] as num).toDouble()).toList()),
      );
    }).toList();
  }

  @override
  List<Object?> get props => [statMonths, statsData, statsLoading];
}

// ─── Bloc ───────────────────────────────────────────────────
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryState()) {
    on<LoadStats>(_onLoadStats);
    on<ChangeFilter>(_onChangeFilter);
    on<DeleteRecord>(_onDeleteRecord);
    on<DeleteAllRecords>(_onDeleteAllRecords);
  }

  Future<void> _onLoadStats(
      LoadStats event, Emitter<HistoryState> emit) async {
    if (!event.silent) emit(state.copyWith(statsLoading: true));
    final from =
        DateTime.now().subtract(Duration(days: state.statMonths * 30));
    final data = await FirestoreService.getRecordsForStats(from);
    emit(state.copyWith(statsData: data, statsLoading: false));
  }

  Future<void> _onChangeFilter(
      ChangeFilter event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(statMonths: event.months, statsLoading: true));
    final from = DateTime.now().subtract(Duration(days: event.months * 30));
    final data = await FirestoreService.getRecordsForStats(from);
    emit(state.copyWith(statsData: data, statsLoading: false));
  }

  Future<void> _onDeleteRecord(
      DeleteRecord event, Emitter<HistoryState> emit) async {
    await FirestoreService.deleteRecord(event.docId);
    add(const LoadStats(silent: true));
  }

  Future<void> _onDeleteAllRecords(
      DeleteAllRecords event, Emitter<HistoryState> emit) async {
    await FirestoreService.deleteAllRecords();
    add(const LoadStats(silent: true));
  }
}

// ─── Data model ─────────────────────────────────────────────
class ChartPoint {
  final String label;
  final double bmi;
  final double weight;
  final double height;
  const ChartPoint({
    required this.label,
    required this.bmi,
    required this.weight,
    required this.height,
  });
}
