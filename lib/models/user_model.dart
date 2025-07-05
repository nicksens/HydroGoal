// lib/models/user_model.dart

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoURL; // Added this to match your UI code

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL, // It's optional
  });

  // Converts an AppUser object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoURL': photoURL,
    };
  }

  // ** IMPORTANT: Creates an AppUser object FROM a Map from Firestore **
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId, // The document ID is the user's UID
      username: map['username'] ?? 'No Name', // Provide default values
      email: map['email'] ?? 'No Email',
      photoURL: map['photoURL'], // This can be null
    );
  }
}