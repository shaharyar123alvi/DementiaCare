import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MemoryVaultScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const MemoryVaultScreen({
    super.key,
    required this.patientId,
    required this.idToken,
  });

  @override
  State<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends State<MemoryVaultScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  final String _bucket = 'dementia-care-9bbf2.firebasestorage.app';
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects';

  List<Map<String, dynamic>> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchVaultImages();
  }

  Future<void> fetchVaultImages() async {
    final url = Uri.parse(
      '$_firestoreUrl/$_projectId/databases/(default)/documents/patients/${widget.patientId}/memoryVault',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final documents = data['documents'] ?? [];

      setState(() {
        _images = documents.map<Map<String, dynamic>>((doc) {
          final fields = doc['fields'] ?? {};
          return {
            'url': fields['url']?['stringValue'] ?? '',
            'title': fields['title']?['stringValue'] ?? '',
            'name': doc['name'], // Firestore doc path
          };
        }).toList();
        _loading = false;
      });
    } else {
      print("Error fetching images: ${response.body}");
      setState(() => _loading = false);
    }
  }

  String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileBytes = await file.readAsBytes();
    final extension = picked.path.split('.').last;
    final contentType = getMimeType(extension);
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

    // Get image title
    String? title = await showDialog<String>(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Enter image title"),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Save")),
          ],
        );
      },
    );

    if (title == null || title.isEmpty) return;

    try {
      final functionUrl = 'https://us-central1-$_projectId.cloudfunctions.net/getSignedUploadUrl';
      final functionResponse = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "filename": "memory_vault/$filename",
          "contentType": contentType
        }),
      );

      if (functionResponse.statusCode != 200) {
        print("❌ Failed to get signed URL: ${functionResponse.body}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get upload URL')));
        return;
      }

      final signedUrl = jsonDecode(functionResponse.body)['signedUrl'];

      final uploadResponse = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );

      if (uploadResponse.statusCode != 200) {
        print("❌ Upload error: ${uploadResponse.body}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
        return;
      }

      final publicUrl = 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/${Uri.encodeComponent("memory_vault/$filename")}?alt=media';
      await saveMetadata(publicUrl, title);
      await fetchVaultImages();
    } catch (e) {
      print("❌ Exception during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error during upload')));
    }
  }

  Future<void> saveMetadata(String url, String title) async {
    final firestoreUrl =
        '$_firestoreUrl/$_projectId/databases/(default)/documents/patients/${widget.patientId}/memoryVault';

    final body = jsonEncode({
      "fields": {
        "url": {"stringValue": url},
        "title": {"stringValue": title},
        "uploadedAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String()
        }
      }
    });

    final response = await http.post(
      Uri.parse(firestoreUrl),
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      print("❌ Failed to save metadata: ${response.body}");
    }
  }

  Future<void> deleteImage(String firestoreDocPath) async {
    final deleteUrl = Uri.parse('https://firestore.googleapis.com/v1/$firestoreDocPath');

    final response = await http.delete(
      deleteUrl,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
      },
    );

    if (response.statusCode == 200) {
      await fetchVaultImages();
    } else {
      print("❌ Failed to delete image: ${response.body}");
    }
  }

  Future<void> editTitle(String firestoreDocPath, String newTitle) async {
    final patchUrl = Uri.parse('https://firestore.googleapis.com/v1/$firestoreDocPath?updateMask.fieldPaths=title');

    final body = jsonEncode({
      "fields": {
        "title": {"stringValue": newTitle}
      }
    });

    final response = await http.patch(
      patchUrl,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      await fetchVaultImages();
    } else {
      print("❌ Failed to update title: ${response.body}");
    }
  }

  void showImageOptions(String firestoreDocPath, String currentTitle) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Title'),
              onTap: () async {
                Navigator.pop(context);
                final controller = TextEditingController(text: currentTitle);
                final newTitle = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Edit Title"),
                    content: TextField(controller: controller),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Update")),
                    ],
                  ),
                );

                if (newTitle != null && newTitle.isNotEmpty) {
                  await editTitle(firestoreDocPath, newTitle);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Image'),
              onTap: () async {
                Navigator.pop(context);
                await deleteImage(firestoreDocPath);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Vault', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('No memories yet.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (_, index) {
                    final image = _images[index];
                    return GestureDetector(
                      onTap: () => showImageOptions(image['name'], image['title']),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              image['url'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(image['title'], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadImage,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
