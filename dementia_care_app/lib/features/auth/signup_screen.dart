import 'package:flutter/material.dart';
import 'package:dementia_care_app/core/services/firebase_auth_service.dart';
import 'package:dementia_care_app/core/services/firestore_service.dart';
import 'package:dementia_care_app/features/auth/login_screen.dart'; // Make sure this import is correct

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'patient'; // Hidden for now, default role
  String _response = '';
  bool _loading = false;

  void _signUp() async {
    setState(() => _loading = true);

    final authService = FirebaseAuthService();
    final firestoreService = FirestoreService();

    final authResult = await authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (authResult.containsKey('idToken')) {
      final firestoreResult = await firestoreService.createDocument(
        collection: 'users',
        data: {
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': DateTime.now().toIso8601String(),
        },
        idToken: authResult['idToken'],
      );

      setState(() {
        _response = '✅ Sign up complete.\n\n$firestoreResult';
      });
    } else {
      setState(() {
        _response = '❌ Sign up failed:\n\n$authResult';
      });
    }

    setState(() => _loading = false);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                CircleAvatar(
  radius: 60, // Adjust size as needed
  backgroundColor: Colors.grey.shade200,
  child: ClipOval(
    child: Image.asset(
      'assets/images/Logo.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    ),
  ),
),
const SizedBox(height: 20),

                const SizedBox(height: 40),
                const Text(
                  'Neura',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,color:Color.fromARGB(255, 7, 54, 78) ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cherishing yesterday, caring for today.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Create an account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 7, 54, 78)),
                ),
                const Text(
                  'Enter your email to sign up for this app',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('email@domain.com'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password.....'),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 7, 54, 78),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _loading ? null : _signUp,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Continue',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    text: 'By clicking continue, you agree to our ',
                    style: TextStyle(color:Color.fromARGB(255, 7, 54, 78), fontSize: 12),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 🔽 New Login Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      color: Color.fromARGB(255, 7, 54, 78),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                if (_response.isNotEmpty)
                  Text(
                    _response,
                    style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 7, 54, 78)),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}