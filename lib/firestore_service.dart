import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>? _recordsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('records');
  }

  /// Save BMI record — enforces ONE record per day (keeps lowest BMI).
  static Future<void> saveRecord({
    required double bmi,
    required double weight,
    required String weightUnit,
    required double height,
    required String heightUnit,
    required String category,
  }) async {
    final col = _recordsCollection();
    if (col == null) return;

    // Build today's midnight boundaries (local time → UTC for Firestore)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Query existing records for today
    final existing = await col
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    if (existing.docs.isNotEmpty) {
      // Today's record already exists — keep only the lowest BMI
      final existingDoc = existing.docs.first;
      final existingBmi = (existingDoc.data()['bmi'] as num).toDouble();

      if (bmi < existingBmi) {
        // New BMI is lower — replace old record
        await existingDoc.reference.delete();
        await col.add({
          'bmi': bmi,
          'weight': weight,
          'weightUnit': weightUnit,
          'height': height,
          'heightUnit': heightUnit,
          'category': category,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // If new BMI >= existing, do nothing (keep old record)
    } else {
      // No record for today — add fresh
      await col.add({
        'bmi': bmi,
        'weight': weight,
        'weightUnit': weightUnit,
        'height': height,
        'heightUnit': heightUnit,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get all records stream (newest first) — UI limits display to last 3 days.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getRecordsStream() {
    final col = _recordsCollection();
    if (col == null) return const Stream.empty();
    return col.orderBy('createdAt', descending: true).snapshots();
  }

  /// Fetch records from [from] date onwards for statistics chart.
  static Future<List<Map<String, dynamic>>> getRecordsForStats(
    DateTime from,
  ) async {
    final col = _recordsCollection();
    if (col == null) return [];

    final snapshot = await col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Delete a single record by its document ID
  static Future<void> deleteRecord(String docId) async {
    final col = _recordsCollection();
    if (col == null) return;
    await col.doc(docId).delete();
  }

  /// Delete all records for current user
  static Future<void> deleteAllRecords() async {
    final col = _recordsCollection();
    if (col == null) return;
    final snapshot = await col.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
