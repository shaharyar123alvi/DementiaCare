import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicationsScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const MedicationsScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  bool loading = true;
  List<Map<String, dynamic>> medications = [];

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  // ✅ Refresh when coming back to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/medications',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded['documents'] as List<dynamic>;

      print("Filtering medications for patientId: ${widget.patientId}");

      medications = docs.where((doc) {
        final docPatientId = doc['fields']['patientId']['stringValue'];
        print("Found doc with patientId: $docPatientId");

        final isMatch = docPatientId == widget.patientId;
        if (isMatch) print("✅ Match found");
        return isMatch;
      }).map((doc) {
        return {
          'id': doc['name'].split('/').last,
          'name': doc['fields']['name']['stringValue'],
          'dosage': doc['fields']['dosage']['stringValue'],
          'notes': doc['fields']['notes']['stringValue'],
          'times': (doc['fields']['times']['arrayValue']?['values'] as List?)
                  ?.map((e) => e['stringValue'])
                  .toList() ??
              [],
        };
      }).toList();
    } else {
      print("❌ Failed to fetch medications: ${response.body}");
    }

    setState(() => loading = false);
  }

  Future<void> _addOrEditMedication({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final dosageController = TextEditingController(text: existing?['dosage'] ?? '');
    final notesController = TextEditingController(text: existing?['notes'] ?? '');
    final timesController = TextEditingController(
      text: existing != null ? (existing['times'] as List).join(', ') : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Medication' : 'Edit Medication'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medication Name')),
              TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
              TextField(controller: timesController, decoration: const InputDecoration(labelText: 'Time(s) (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "fields": {
                  "name": {"stringValue": nameController.text.trim()},
                  "dosage": {"stringValue": dosageController.text.trim()},
                  "notes": {"stringValue": notesController.text.trim()},
                  "times": {
                    "arrayValue": {
                      "values": timesController.text
                          .split(',')
                          .map((e) => {"stringValue": e.trim()})
                          .toList()
                    }
                  },
                  "patientId": {"stringValue": widget.patientId},
                }
              };

              if (existing == null) {
                final url = Uri.parse(
                  'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/medications',
                );

                await http.post(
                  url,
                  headers: {
                    'Authorization': 'Bearer ${widget.idToken}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(data),
                );
              } else {
                final url = Uri.parse(
                  'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/medications/${existing['id']}',
                );

                await http.patch(
                  url,
                  headers: {
                    'Authorization': 'Bearer ${widget.idToken}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(data),
                );
              }

              Navigator.pop(context);
              _fetchMedications();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(String id) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/medications/$id',
    );

    await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    _fetchMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : medications.isEmpty
              ? const Center(child: Text('No medications found. Tap + to add.'))
              : ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (_, index) {
                    final med = medications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey.shade100,
                      child: ListTile(
                        onTap: () => _addOrEditMedication(existing: med),
                        title: Text(med['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dosage: ${med['dosage']}'),
                            Text('Times: ${(med['times'] as List).join(', ')}'),
                            Text('Notes: ${med['notes']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMedication(med['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMedication(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
