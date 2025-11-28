import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientListScreen extends StatefulWidget {
  final String caregiverEmail;
  final String idToken;

  const PatientListScreen({
    super.key,
    required this.caregiverEmail,
    required this.idToken,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;

  final String _projectId = 'dementia-care-9bbf2';
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects';

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final url = Uri.parse(
        '$_firestoreUrl/$_projectId/databases/(default)/documents:runQuery');

    final body = jsonEncode({
      "structuredQuery": {
        "from": [{"collectionId": "patients"}],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "caregivers"},
            "op": "ARRAY_CONTAINS",
            "value": {"stringValue": widget.caregiverEmail}
          }
        }
      }
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      setState(() {
        _patients = decoded
            .where((e) => e['document'] != null)
            .map<Map<String, dynamic>>((e) => {
                  'id': e['document']['name'].split('/').last,
                  ...e['document']['fields'].map((key, val) =>
                      MapEntry(key, val[val.keys.first]))
                })
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showRoleDialog(String patientId, String patientName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Continue as"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/caregiverHome',
                  arguments: {
                    'patientId': patientId,
                    'idToken': widget.idToken,
                  },
                );
              },
              child: const Text("Caregiver", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/patientHome',
                  arguments: {
                    'patientId': patientId,
                    'idToken': widget.idToken,
                    'patientName': patientName,
                  },
                );
              },
              child: const Text("Patient", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _goToAddPatient() async {
    final result = await Navigator.pushNamed(context, '/addPatient', arguments: {
      'caregiverEmail': widget.caregiverEmail,
      'idToken': widget.idToken,
    });
    if (result == true) {
      fetchPatients(); // refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Patients", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: ElevatedButton(
                    onPressed: _goToAddPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text("ADD Patient", style: TextStyle(color: Colors.white)),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return ListTile(
                            leading: const Icon(Icons.account_circle_rounded, size: 40),
                            title: Text(patient['name'] ?? 'Unnamed'),
                            subtitle: Text(patient['condition'] ?? 'No condition info'),
                            onTap: () => _showRoleDialog(patient['id'], patient['name'] ?? ''),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _goToAddPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("ADD Patient", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
    );
  }
}
