import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hydrogoal/models/user_model.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';
import 'package:hydrogoal/services/firebase_auth_service.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late final TextEditingController _usernameController;

  Future<AppUser?>? _userFuture;
  bool _isEditing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _userFuture = _fetchUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<AppUser?> _fetchUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await _firestoreService.getUser(firebaseUser.uid);
      if (user != null) {
        _usernameController.text = user.username; // Initialize controller
      }
      return user;
    }
    return null;
  }

  Future<void> _updateUsername() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar(context, 'Username cannot be empty.', isError: true);
      return;
    }

    // Show a loading indicator while saving
    setState(() {}); // Rebuild to show potential loading state if added

    try {
      await _firestoreService.updateUsername(
        firebaseUser.uid,
        _usernameController.text.trim(),
      );

      setState(() {
        _isEditing = false;
        // Refresh user data to show the new name
        _userFuture = _fetchUserData();
      });
      _showSnackBar(context, 'Username updated successfully!');
    } catch (e) {
      _showSnackBar(context, 'Failed to update username.', isError: true);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final imagePicker = ImagePicker();
    // Open the device camera
    final pickedXFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Compress image to save storage space
      maxWidth: 800,
    );

    // If the user didn't pick an image, do nothing
    if (pickedXFile == null) return;

    setState(() {
      _isUploading = true; // Show loading indicator
    });

    try {
      final imageFile = File(pickedXFile.path);
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${firebaseUser.uid}.jpg');

      // Upload the file
      await storageRef.putFile(imageFile);

      // Get the download URL
      final newPhotoURL = await storageRef.getDownloadURL();

      // Update the URL in Firestore
      await _firestoreService.updatePhotoURL(firebaseUser.uid, newPhotoURL);

      // Refresh the UI with the new data
      setState(() {
        _userFuture = _fetchUserData();
      });

      _showSnackBar(context, 'Profile picture updated!');
    } catch (e) {
      _showSnackBar(context, 'Failed to upload image. Please try again.', isError: true);
    } finally {
      setState(() {
        _isUploading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error signing out. Please try again.', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
      ),
    );
  }

  Widget _buildUsernameWidget() {
    // This function builds the username display or the text field
    if (_isEditing) {
      // EDITING MODE: A Row with an Expanded TextField works well here.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _usernameController,
              autofocus: true,
              // This is the key for centering the text inside the field
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                // The contentPadding can be adjusted as needed
                contentPadding: EdgeInsets.fromLTRB(0, 8, 0, 8),
              ),
            ),
          ),
          // Save and Cancel buttons appear on the right
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: _updateUsername,
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: Colors.red[400]),
            onPressed: () {
              setState(() {
                _isEditing = false;
                // Reload the original username from the future snapshot
                _userFuture?.then((user) {
                  if (user != null) {
                    _usernameController.text = user.username;
                  }
                });
              });
            },
          ),
        ],
      );
    } else {
      // VIEWING MODE: Use a Stack to perfectly center the name
      return Stack(
        alignment: Alignment.center, // Default alignment is center
        children: [
          // WIDGET 1: The username, always centered
          Center(
            child: Text(
              _usernameController.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          // WIDGET 2: The edit icon, aligned to the right of the stack
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFEFF6FF),
        elevation: 0,
      ),
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Could not load profile data.'));
          }

          final userData = snapshot.data!;

          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      // --- AVATAR WIDGET ---
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: (userData.photoURL != null && userData.photoURL!.isNotEmpty)
                            ? NetworkImage(userData.photoURL!)
                            : null,
                        child: (userData.photoURL == null || userData.photoURL!.isEmpty)
                            ? Icon(Icons.person, size: 70, color: Colors.grey.shade500)
                            : null,
                      ),
                      // --- CAMERA ICON ---
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.blue[500],
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            // CONNECTING THE FUNCTION TO THE BUTTON
                            onTap: _pickAndUploadImage,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // --- UPLOADING INDICATOR ---
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.black45,
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUsernameWidget(),
                  const SizedBox(height: 8),
                  Text(
                    userData.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom( /* ... */ ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}