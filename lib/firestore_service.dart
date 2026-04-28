import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>? _recordsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('records');
  }

  /// Save BMI record to Firestore
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

  /// Get all records stream (newest first)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getRecordsStream() {
    final col = _recordsCollection();
    if (col == null) return const Stream.empty();
    return col.orderBy('createdAt', descending: true).snapshots();
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
