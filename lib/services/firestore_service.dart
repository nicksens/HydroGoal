import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydrogoal/models/user_model.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> logWaterIntake(String userId, int amount) async {
    final String dateId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('hydration_history')
        .doc(dateId);
    return docRef.set({
      'amount': FieldValue.increment(amount),
      'date': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // --- THIS IS THE NEW, MISSING METHOD ---
  Future<int> getTodaysIntake(String userId) async {
    final String dateId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('hydration_history')
        .doc(dateId)
        .get();
    if (doc.exists) {
      return (doc.data()?['amount'] ?? 0) as int;
    }
    return 0;
  }

  Stream<QuerySnapshot> getHydrationHistoryForMonth(
      String userId, DateTime month) {
    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _db
        .collection('users')
        .doc(userId)
        .collection('hydration_history')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .snapshots();
  }
}
