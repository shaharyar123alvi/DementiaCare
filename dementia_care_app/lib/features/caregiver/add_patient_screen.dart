import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddPatientScreen extends StatefulWidget {
  final String caregiverEmail;
  final String idToken;

  const AddPatientScreen({
    super.key,
    required this.caregiverEmail,
    required this.idToken,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Male';
  bool _submitting = false;

  final String _projectId = 'dementia-care-9bbf2';
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects';

 Future<void> _submitPatient() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _submitting = true);

  final url = Uri.parse(
    '$_firestoreUrl/$_projectId/databases/(default)/documents/patients',
  );

  final body = jsonEncode({
    "fields": {
      "name": {"stringValue": _nameController.text.trim()},
      "age": {"stringValue": _ageController.text.trim()},
      "gender": {"stringValue": _selectedGender},
      "condition": {"stringValue": _conditionController.text.trim()},
      "medications": {"stringValue": _medicationsController.text.trim()},
      "notes": {"stringValue": _notesController.text.trim()},
      "caregivers": {
        "arrayValue": {
          "values": [
            {"stringValue": widget.caregiverEmail}
          ]
        }
      },
      "createdAt": {
        "timestampValue": DateTime.now().toUtc().toIso8601String()
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

  setState(() => _submitting = false);

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Patient added successfully!')),
    );
    Navigator.pop(context, true); // return true to refresh list
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to add patient:\n${response.body}')),
    );
  }
}

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
      appBar: AppBar(
        title: const Text('Add Patient', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Full Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Age'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _inputDecoration('Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _conditionController,
                  decoration: _inputDecoration('Medical Condition'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicationsController,
                  decoration: _inputDecoration('Previous Medications'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('Other Notes or Concerns'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Patient",
                            style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
