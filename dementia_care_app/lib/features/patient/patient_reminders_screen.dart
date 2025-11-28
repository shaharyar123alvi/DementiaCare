import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class PatientRemindersScreen extends StatefulWidget {
  final String patientId;
  final String caregiverEmail;
  final String idToken;

  const PatientRemindersScreen({
    required this.patientId,
    required this.caregiverEmail,
    required this.idToken,
    Key? key,
  }) : super(key: key);

  @override
  State<PatientRemindersScreen> createState() => _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  String selectedFilter = 'All';
  List<Map<String, dynamic>> reminders = [];
  bool isLoading = true;

  final filters = ['All', 'Morning', 'Afternoon', 'Night'];
  final player = AudioPlayer();

  // 🔁 Unified bucket logic like Memory Vault
  final String _projectId = 'dementia-care-9bbf2';
  final String _bucket = 'dementia-care-9bbf2.firebasestorage.app';
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects';

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      '$_firestoreUrl/$_projectId/databases/(default)/documents/reminders',
    );

    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer ${widget.idToken}',
      });

      if (res.statusCode != 200) {
        print("Failed to fetch reminders: ${res.body}");
        setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(res.body);
      final docs = data['documents'] ?? [];

      final List<Map<String, dynamic>> fetched = [];

      for (var doc in docs) {
        final fields = doc['fields'] ?? {};
        final patientId = fields['patientId']?['stringValue'] ?? '';
        if (patientId != widget.patientId) continue;

        final timeStr = fields['time']?['stringValue'];
        if (timeStr == null) continue;

        final DateTime parsedTime = DateTime.tryParse(timeStr) ?? DateTime.now();
        final hour = parsedTime.hour;

        if (_filterMatch(hour)) {
          fetched.add({
            'id': doc['name'].split('/').last,
            'title': fields['name']?['stringValue'] ?? '(No Title)',
            'type': fields['type']?['stringValue'] ?? '',
            'time': "${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}",
            'audioUrl': fields['audioUrl']?['stringValue'],
          });
        }
      }

      setState(() {
        reminders = fetched;
        isLoading = false;
      });
    } catch (e, st) {
      print("Exception while fetching reminders: $e");
      print(st);
      setState(() => isLoading = false);
    }
  }

  bool _filterMatch(int hour) {
    switch (selectedFilter) {
      case 'Morning':
        return hour >= 5 && hour < 12;
      case 'Afternoon':
        return hour >= 12 && hour < 18;
      case 'Night':
        return hour >= 18 && hour < 24;
      default:
        return true;
    }
  }

  Future<void> markAsDone(Map<String, dynamic> reminder) async {
  final now = DateTime.now().toUtc();
  final trackingUrl = Uri.parse(
    '$_firestoreUrl/$_projectId/databases/(default)/documents/reminderTracking',
  );

  final scheduledTime = reminder['time'] ?? '00:00';
  final today = DateTime.now();
  final parts = scheduledTime.split(':');
  final scheduledDateTime = DateTime(
    today.year, today.month, today.day,
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 0,
  ).toUtc();

  // 🔁 Log to reminderTracking
  final trackingBody = jsonEncode({
    "fields": {
      "patientId": {"stringValue": widget.patientId},
      "reminderId": {"stringValue": reminder['id'] ?? ''},
      "reminderName": {"stringValue": reminder['title'] ?? ''},
      "reminderType": {"stringValue": reminder['type'] ?? ''},
      "scheduledTime": {"timestampValue": scheduledDateTime.toIso8601String()},
      "actualTime": {"timestampValue": now.toIso8601String()},
    }
  });

  await http.post(trackingUrl,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: trackingBody);

  // 🔁 Original notification logic (unchanged)
  final notifUrl = Uri.parse(
    '$_firestoreUrl/$_projectId/databases/(default)/documents/notifications',
  );

  final body = jsonEncode({
    "fields": {
      "patientId": {"stringValue": widget.patientId},
      "caregiverEmail": {"stringValue": widget.caregiverEmail},
      "reminderName": {"stringValue": reminder['title']},
      "reminderType": {"stringValue": reminder['type']},
      "status": {"stringValue": "done"},
      "completedAt": {"timestampValue": now.toIso8601String()}
    }
  });

  final res = await http.post(notifUrl, headers: {
    'Authorization': 'Bearer ${widget.idToken}',
    'Content-Type': 'application/json',
  }, body: body);

  if (res.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Marked '${reminder['title']}' as done.")),
    );
  } else {
    print("Failed to create notification: ${res.body}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to mark as done.")),
    );
  }
}


  void playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No audio attached")),
      );
      return;
    }

    try {
      await player.stop();

      final fullAudioUrl = audioUrl.startsWith("http")
          ? audioUrl
          : 'https://$_bucket/o/${Uri.encodeComponent(audioUrl)}?alt=media';

      print("🎧 Playing audio: $fullAudioUrl");
      await player.play(UrlSource(fullAudioUrl));
    } catch (e) {
      print("❌ Error playing audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to play audio")),
      );
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Reminders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              isSelected: filters.map((f) => f == selectedFilter).toList(),
              onPressed: (index) {
                setState(() {
                  selectedFilter = filters[index];
                });
                fetchReminders();
              },
              children: filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(f),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : reminders.isEmpty
                    ? const Center(child: Text("No upcoming reminders"))
                    : ListView.builder(
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final r = reminders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(r['title']),
                              subtitle: Text("Time: ${r['time']} • ${r['type']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (r['audioUrl'] != null && r['audioUrl'].toString().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.volume_up),
                                      onPressed: () => playAudio(r['audioUrl']),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline),
                                    onPressed: () => markAsDone(r),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
