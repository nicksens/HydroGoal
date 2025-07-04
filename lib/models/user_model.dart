class AppUser {
  final String uid;
  final String username;
  final String email;

  AppUser({required this.uid, required this.username, required this.email});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'username': username, 'email': email};
  }
}
