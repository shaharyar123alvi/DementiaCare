import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';

class RemindersScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const RemindersScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  final String _functionUrl = 'https://us-central1-dementia-care-9bbf2.cloudfunctions.net/getSignedUploadUrl';
  final String _bucket = 'dementia-care-9bbf2.firebasestorage.app';

  final audioRecorder = Record();
  File? recordedFile;
  bool isRecording = false;
  bool loading = true;

  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/reminders');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.idToken}',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded['documents'] as List<dynamic>;

      reminders = docs
          .where((doc) => doc['fields']['patientId']['stringValue'] == widget.patientId)
          .map((doc) => {
                'id': doc['name'].split('/').last,
                'name': doc['fields']['name']['stringValue'],
                'type': doc['fields']['type']['stringValue'],
                'time': doc['fields']['time']['stringValue'],
                'audioUrl': doc['fields']['audioUrl']?['stringValue'],
              })
          .toList();
    }

    setState(() => loading = false);
  }

  Future<void> _deleteReminder(String reminderId) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/reminders/$reminderId',
    );

    await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    _fetchReminders();
  }

  Future<String> uploadAudioToFirebase(File file) async {
    final cleanName = file.path.split('/').last.replaceAll(' ', '_');
    final filename = 'audio_reminders/${DateTime.now().millisecondsSinceEpoch}_$cleanName';

    final extension = file.path.split('.').last.toLowerCase();
    final mimeType = extension == 'mp3' ? 'audio/mpeg' : 'audio/m4a';

    print("Preparing upload for: $filename");

    final signedRes = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"filename": filename, "contentType": mimeType}),
    );

    print("Signed URL response: ${signedRes.statusCode}");
    print("Signed URL body: ${signedRes.body}");

    if (signedRes.statusCode != 200) {
      throw Exception("Failed to get signed URL");
    }

    final signedUrl = jsonDecode(signedRes.body)['signedUrl'];

    final uploadRes = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': mimeType},
      body: await file.readAsBytes(),
    );

    print("Upload response code: ${uploadRes.statusCode}");
    print("Upload response body: ${uploadRes.body}");

    if (uploadRes.statusCode != 200) {
      throw Exception("Upload failed");
    }

    final fullUrl = 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/${Uri.encodeComponent(filename)}?alt=media';
    print("✅ Uploaded! Audio URL: $fullUrl");

    return fullUrl;
  }

  Future<List<Map<String, dynamic>>> _fetchItems(String type) async {
    final collection = type == 'Medication' ? 'medications' : 'appointments';
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded['documents'] as List<dynamic>;

      return docs
          .where((doc) => doc['fields']['patientId']['stringValue'] == widget.patientId)
          .map((doc) => {
                'id': doc['name'].split('/').last,
                'name': type == 'Medication'
                    ? doc['fields']['name']['stringValue']
                    : doc['fields']['title']['stringValue'],
                'times': type == 'Medication'
                    ? (doc['fields']['times']['arrayValue']?['values'] as List?)
                            ?.map((e) => e['stringValue'])
                            .toList() ??
                        []
                    : [doc['fields']['datetime']['stringValue']],
              })
          .toList();
    }

    return [];
  }

  Future<void> _addReminderByType(String reminderType) async {
    String? selectedItemName;
    List<String> selectedTimes = [];
    recordedFile = null;

    final items = await _fetchItems(reminderType);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add $reminderType Reminder"),
        content: StatefulBuilder(
          builder: (context, setState) {
            Future<void> startRecording() async {
              if (await audioRecorder.hasPermission()) {
                final dir = await getApplicationDocumentsDirectory();
                final path = '${dir.path}/reminder_${DateTime.now().millisecondsSinceEpoch}.m4a';
                await audioRecorder.start(path: path);
                setState(() => isRecording = true);
              }
            }

            Future<void> stopRecording() async {
              final path = await audioRecorder.stop();
              setState(() {
                recordedFile = File(path!);
                isRecording = false;
              });
            }

            Future<void> pickAudio() async {
              final picked = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (picked != null) {
                setState(() => recordedFile = File(picked.files.single.path!));
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  hint: const Text("Select Item"),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'],
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final item = items.firstWhere((e) => e['id'] == value);
                    setState(() {
                      selectedItemName = item['name'];
                      selectedTimes = List<String>.from(item['times']);
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedTimes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedTimes.map((t) => Text("• $t")).toList(),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isRecording ? stopRecording : startRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  label: Text(isRecording ? "Stop Recording" : "Record Voice Reminder"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: pickAudio,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Voice File"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
                const SizedBox(height: 10),
                if (recordedFile != null)
                  const Text("🎤 Audio attached", style: TextStyle(color: Colors.green)),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (selectedItemName != null) {
                for (final time in selectedTimes) {
                  final Map<String, dynamic> reminderData = {
                    "fields": {
                      "type": {"stringValue": reminderType},
                      "name": {"stringValue": selectedItemName},
                      "time": {"stringValue": time},
                      "patientId": {"stringValue": widget.patientId},
                    }
                  };

                  if (recordedFile != null) {
                    final audioUrl = await uploadAudioToFirebase(recordedFile!);
                    reminderData['fields']["audioUrl"] = {"stringValue": audioUrl};
                  }

                  final url = Uri.parse(
                    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/reminders',
                  );

                  await http.post(
                    url,
                    headers: {
                      'Authorization': 'Bearer ${widget.idToken}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(reminderData),
                  );
                }

                Navigator.pop(context);
                _fetchReminders();
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? const Center(child: Text("No reminders yet. Tap + to add."))
              : ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (_, index) {
                    final reminder = reminders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey.shade100,
                      child: ListTile(
                        title: Text("${reminder['type']} - ${reminder['name']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Time: ${reminder['time']}"),
                            if (reminder['audioUrl'] != null)
                              Text("🔉 Voice Attached", style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReminder(reminder['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            backgroundColor: Colors.black,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Med Reminder", style: TextStyle(color: Colors.white)),
            onPressed: () => _addReminderByType('Medication'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            backgroundColor: Colors.black,
            icon: const Icon(Icons.add_alert, color: Colors.white),
            label: const Text("Add Appt Reminder", style: TextStyle(color: Colors.white)),
            onPressed: () => _addReminderByType('Appointment'),
          ),
        ],
      ),
    );
  }
}
