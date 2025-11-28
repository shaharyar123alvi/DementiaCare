import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddMemoryVaultScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const AddMemoryVaultScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<AddMemoryVaultScreen> createState() => _AddMemoryVaultScreenState();
}

class _AddMemoryVaultScreenState extends State<AddMemoryVaultScreen> {
  File? _selectedImage;
  final _titleController = TextEditingController();
  bool _uploading = false;

  final String _bucket = 'dementia-care-9bbf2.appspot.com';
  final String _projectId = 'dementia-care-9bbf2';

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadToFirebaseStorage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$_bucket/o?uploadType=media&name=memory_vault/${widget.patientId}/$fileName',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'image/jpeg', // You can adjust based on the file
      },
      body: await imageFile.readAsBytes(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final downloadToken = json['downloadTokens'];
      final downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/${Uri.encodeComponent('memory_vault/${widget.patientId}/$fileName')}?alt=media&token=$downloadToken';
      return downloadUrl;
    } else {
      print('Upload error: ${response.body}');
      return null;
    }
  }

  Future<void> _saveMetadataToFirestore(String url) async {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/memoryVault',
    );

    final body = jsonEncode({
      "fields": {
        "url": {"stringValue": url},
        "title": {"stringValue": _titleController.text.trim()},
        "patientId": {"stringValue": widget.patientId},
        "uploadedAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String()
        }
      }
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Memory image saved!')),
      );
      Navigator.pop(context, true);
    } else {
      print('Firestore error: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to save metadata')),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick image and enter title')),
      );
      return;
    }

    setState(() => _uploading = true);

    final imageUrl = await _uploadToFirebaseStorage(_selectedImage!);
    if (imageUrl != null) {
      await _saveMetadataToFirestore(imageUrl);
    }

    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Memory Vault Image', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Image from Gallery'),
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Image Caption',
                filled: true,
                fillColor: Color(0xFFF2F2F2),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload Image', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
