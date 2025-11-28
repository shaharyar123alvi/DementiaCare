import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentsScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const AppointmentsScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  bool loading = true;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/appointments',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded['documents'] as List<dynamic>? ?? [];

      appointments = docs
          .where((doc) =>
              doc['fields']['patientId']['stringValue'] == widget.patientId)
          .map((doc) => {
                'id': doc['name'].split('/').last,
                'title': doc['fields']['title']['stringValue'],
                'datetime': doc['fields']['datetime']['stringValue'],
                'notes': doc['fields']['notes']['stringValue'],
              })
          .toList();
    }

    setState(() => loading = false);
  }

  Future<void> _addAppointment() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Appointment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                    }
                  }
                },
                child: const Text("Pick Date & Time"),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || selectedDate == null) return;
              final data = {
                "fields": {
                  "title": {"stringValue": titleController.text.trim()},
                  "datetime": {"stringValue": selectedDate!.toIso8601String()},
                  "notes": {"stringValue": notesController.text.trim()},
                  "patientId": {"stringValue": widget.patientId},
                }
              };

              final url = Uri.parse(
                'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/appointments',
              );

              await http.post(
                url,
                headers: {
                  'Authorization': 'Bearer ${widget.idToken}',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(data),
              );

              Navigator.pop(context);
              _fetchAppointments();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('No appointments found. Tap + to add.'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (_, index) {
                    final appt = appointments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey.shade100,
                      child: ListTile(
                        title: Text(appt['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time: ${appt['datetime']}'),
                            Text('Notes: ${appt['notes']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
