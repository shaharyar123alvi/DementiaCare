import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaregiverNotificationScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const CaregiverNotificationScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<CaregiverNotificationScreen> createState() => _CaregiverNotificationScreenState();
}

class _CaregiverNotificationScreenState extends State<CaregiverNotificationScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final notifUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/notifications',
    );

    final notifRes = await http.get(
      notifUrl,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
      },
    );

    if (notifRes.statusCode == 200) {
      final decoded = jsonDecode(notifRes.body);
      final docs = decoded['documents'] ?? [];

      final List<Map<String, dynamic>> filtered = docs.map<Map<String, dynamic>>((doc) {

        final fields = doc['fields'] ?? {};
        return {
          'message':
              "${fields['reminderType']?['stringValue']} Reminder: ${fields['reminderName']?['stringValue']} was marked as ${fields['status']?['stringValue']}",
          'timestamp': fields['completedAt']?['timestampValue'] ?? '',
          'patientId': fields['patientId']?['stringValue'] ?? '',
        };
      }).where((notif) => notif['patientId'] == widget.patientId).toList();

      filtered.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _notifications = filtered;
        _loading = false;
      });
    } else {
      print("❌ Notification fetch failed: ${notifRes.statusCode}");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text("No notifications available."))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final notif = _notifications[index];
                    final time = DateTime.tryParse(notif['timestamp'])?.toLocal();
                    return ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.black),
                      title: Text(notif['message']),
                      subtitle: Text(
                        time != null ? '${time.toLocal()}' : 'Unknown time',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
    );
  }
}
