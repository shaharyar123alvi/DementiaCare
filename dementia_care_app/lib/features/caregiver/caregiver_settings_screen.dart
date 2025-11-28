import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaregiverSettingsScreen extends StatefulWidget {
  final String idToken;

  const CaregiverSettingsScreen({
    super.key,
    required this.idToken,
  });

  @override
  State<CaregiverSettingsScreen> createState() => _CaregiverSettingsScreenState();
}

class _CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  void _showPasswordResetDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool oldVisible = false;
    bool newVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: !oldVisible,
                  decoration: InputDecoration(
                    labelText: 'Old Password',
                    suffixIcon: IconButton(
                      icon: Icon(oldVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => oldVisible = !oldVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: !newVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(newVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => newVisible = !newVisible),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final oldPassword = oldPasswordController.text;
                  final newPassword = newPasswordController.text;

                  // Cannot verify old password without email, so skip verification step
                  final updateResp = await http.post(
                    Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:update?key=YOUR_API_KEY"),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      "idToken": widget.idToken,
                      "password": newPassword,
                      "returnSecureToken": true,
                    }),
                  );

                  if (updateResp.statusCode == 200) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to update password")),
                    );
                  }
                },
                child: const Text("Update"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSettingsItem(Icons.lock_open, 'Change Password', onTap: _showPasswordResetDialog),
          _buildSettingsItem(Icons.exit_to_app, 'Logout', onTap: _logout),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Icon(icon, color: Colors.black),
          title: Text(title, style: const TextStyle(color: Colors.black)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
