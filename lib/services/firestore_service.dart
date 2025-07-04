import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydrogoal/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }
}
