import 'package:flutter/material.dart';
import 'package:dementia_care_app/core/services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _signIn() async {
    setState(() => _loading = true);

    final authService = FirebaseAuthService();
    final result = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (result.containsKey('idToken')) {
      // ✅ Navigate to patient list
      Navigator.pushReplacementNamed(
        context,
        '/patientList',
        arguments: {
          'email': _emailController.text.trim(),
          'idToken': result['idToken'],
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Login failed: ${result['error']}')),
      );
    }
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 7, 54, 78)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cherishing yesterday, caring for today.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color:Color.fromARGB(255, 7, 54, 78)),
                ),
                const Text(
                  'Login to your account',
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
                Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.pushNamed(context, '/forgotPassword');
    },
    child: const Text(
      'Forgot Password?',
      style: TextStyle(
        fontSize: 14,
        color: Color.fromARGB(255, 7, 54, 78),
        decoration: TextDecoration.underline,
      ),
    ),
  ),
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
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
