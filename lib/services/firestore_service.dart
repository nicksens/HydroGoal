import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydrogoal/models/bottle_model.dart';
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

  Future<AppUser?> getUser(String uid) async {
    try {
      final docSnapshot = await _db.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        // Use the fromMap factory you added to user_model.dart
        return AppUser.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    // Return null if user isn't found or an error occurs
    return null;
  }

  Future<void> updateUsername(String uid, String newUsername) async {
    try {
      await _db.collection('users').doc(uid).update({
        'username': newUsername,
      });
    } catch (e) {
      print('Error updating username: $e');
      // Optionally re-throw the exception to handle it in the UI
      rethrow;
    }
  }

  Future<void> updatePhotoURL(String uid, String newPhotoURL) async {
    try {
      await _db.collection('users').doc(uid).update({
        'photoURL': newPhotoURL,
      });
    } catch (e) {
      print('Error updating photo URL: $e');
      rethrow;
    }
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

  Future<void> addBottle(String userId, String name, int capacity) async {
    await _db.collection('users').doc(userId).collection('bottles').add({
      'name': name,
      'capacity': capacity,
    });
  }

  /// Gets a real-time stream of the user's saved bottles.
  Stream<List<Bottle>> getBottles(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bottles')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bottle.fromSnapshot(doc)).toList());
  }

  /// Deletes a bottle from the user's inventory.
  Future<void> deleteBottle(String userId, String bottleId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('bottles')
        .doc(bottleId)
        .delete();
  }
}
