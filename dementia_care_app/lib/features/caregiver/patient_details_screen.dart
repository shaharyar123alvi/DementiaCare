import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  bool loading = true;

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController genderController;
  late TextEditingController conditionController;
  late TextEditingController medicationsController;
  late TextEditingController notesController;
  List<String> caregiversList = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    ageController = TextEditingController();
    genderController = TextEditingController();
    conditionController = TextEditingController();
    medicationsController = TextEditingController();
    notesController = TextEditingController();
    _fetchPatientDetails();
  }

  Future<void> _fetchPatientDetails() async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/patients/${widget.patientId}',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['fields'];
      setState(() {
        nameController.text = data['name']['stringValue'] ?? '';
        ageController.text = data['age']['stringValue'] ?? '';
        genderController.text = data['gender']['stringValue'] ?? '';
        conditionController.text = data['condition']['stringValue'] ?? '';
        medicationsController.text = data['medications']['stringValue'] ?? '';
        notesController.text = data['notes']['stringValue'] ?? '';
        caregiversList = (data['caregivers']['arrayValue']?['values'] as List<dynamic>?)
                ?.map((e) => e['stringValue'] as String)
                .toList() ??
            [];
        loading = false;
      });
    } else {
      print('Error: ${response.body}');
      setState(() => loading = false);
    }
  }

  Future<void> _updatePatientDetails() async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/patients/${widget.patientId}',
    );

    final data = {
      "fields": {
        "name": {"stringValue": nameController.text},
        "age": {"stringValue": ageController.text},
        "gender": {"stringValue": genderController.text},
        "condition": {"stringValue": conditionController.text},
        "medications": {"stringValue": medicationsController.text},
        "notes": {"stringValue": notesController.text},
        "caregivers": {
          "arrayValue": {
            "values": caregiversList.map((c) => {"stringValue": c}).toList()
          }
        }
      }
    };

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient details updated successfully')),
      );
    } else {
      print('Failed to update: ${response.body}');
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Patient Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Name", nameController),
                  _buildTextField("Age", ageController),
                  _buildTextField("Gender", genderController),
                  _buildTextField("Condition", conditionController),
                  _buildTextField("Medications", medicationsController),
                  _buildTextField("Notes", notesController),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updatePatientDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
