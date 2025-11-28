import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String _message = '';

  Future<void> sendPasswordResetEmail(String email) async {
    setState(() {
      _loading = true;
      _message = '';
    });

    final url = Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=AIzaSyBPJMuBHvwiFf55gj3HP6zgkcZ0KkNLZJs");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestType': 'PASSWORD_RESET',
        'email': email,
      }),
    );

    setState(() {
      _loading = false;
      if (response.statusCode == 200) {
        _message = 'Password reset email sent! Please check your inbox.';
      } else {
        final error = jsonDecode(response.body)['error']['message'];
        _message = 'Error: $error';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Enter your registered email to receive password reset instructions.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : () => sendPasswordResetEmail(_emailController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: _loading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Send Reset Email", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
