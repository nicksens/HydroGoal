import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hydrogoal/models/user_model.dart';
import 'package:hydrogoal/services/firebase_auth_service.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:hydrogoal/screens/home_screen.dart';
import 'package:hydrogoal/screens/auth/login_screen.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:hydrogoal/widgets/wave_clipper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      User? user = await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text.trim());
      if (user != null) {
        AppUser newUser = AppUser(
            uid: user.uid,
            username: _usernameController.text.trim(),
            email: user.email!);
        await _firestoreService.createUser(newUser);
        if (mounted)
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        default:
          message = 'An unexpected error occurred.';
      }
      setState(() => _errorMessage = message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 250,
              color: AppColors.primaryBlue.withOpacity(0.2),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.water_drop_outlined,
                          size: 60, color: AppColors.primaryBlue),
                      const SizedBox(height: 20),
                      const Text('Create Account',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText),
                          textAlign: TextAlign.center),
                      const Text('Start your hydration journey',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.lightText),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline)),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter a username'
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter an email';
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                            return 'Please enter a valid email address';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter a password';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signUp(),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.errorRed, fontSize: 14),
                              textAlign: TextAlign.center),
                        ),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signUp, child: const Text('SIGN UP')),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?",
                              style: TextStyle(color: AppColors.lightText)),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                                    builder: (context) => const LoginScreen())),
                            child: const Text('Log In',
                                style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ]
                        // This is the corrected animation call
                        .animate(interval: 100.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.5, curve: Curves.easeOut),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
