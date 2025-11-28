import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shimmer/shimmer.dart';

const String hardcodedCaregiverPassword = 'myCaregiver123';

class PatientHomeScreen extends StatefulWidget {
  final String patientId;
  final String idToken;
  final String patientName;

  const PatientHomeScreen({
    super.key,
    required this.patientId,
    required this.idToken,
    required this.patientName,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}


  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();


class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final String _projectId = 'dementia-care-9bbf2';
  final String _bucket = 'dementia-care-9bbf2.firebasestorage.app';
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects';

  Map<String, dynamic>? nextReminder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String caregiverEmail = 'ali@gmail.com';

  @override
  void initState() {
    super.initState();
    fetchNextReminder();
  }

  Future<void> fetchNextReminder() async {
    final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/reminders');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded['documents'] as List<dynamic>;

      final reminders = docs
          .where((doc) => doc['fields']['patientId']['stringValue'] == widget.patientId)
          .map((doc) {
        final fields = doc['fields'];
        return {
          'type': fields['type']['stringValue'],
          'name': fields['name']['stringValue'],
          'time': fields['time']['stringValue'],
          'audioUrl': fields['audioUrl']?['stringValue'],
        };
      }).toList();

      if (reminders.isNotEmpty) {
        reminders.sort((a, b) => a['time'].compareTo(b['time']));
        setState(() {
          nextReminder = reminders.first;
        });
      }
    }
  }

  void playAudio(String audioUrl) async {
    String url;

    if (audioUrl.startsWith('http')) {
      url = audioUrl;
    } else {
      final encodedPath = Uri.encodeComponent(audioUrl);
      url = 'https://firebasestorage.googleapis.com/v0/b/dementia-care-9bbf2.firebasestorage.app/o/$encodedPath?alt=media';
    }

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to play audio")),
      );
    }
  }

  void _promptPasswordAndNavigateBack() {
    String enteredPassword = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Caregiver Password'),
        content: TextField(
          obscureText: true,
          onChanged: (val) => enteredPassword = val,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (enteredPassword == hardcodedCaregiverPassword) {
                Navigator.pushNamed(context, '/caregiverHome', arguments: {
                  'patientId': widget.patientId,
                  'idToken': widget.idToken,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect password")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(147, 255, 210, 206), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _promptPasswordAndNavigateBack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hello, ${widget.patientName}!',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (nextReminder != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        'What’s Next? ${nextReminder!['type']} - ${nextReminder!['name']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600) ,
                      ),
                      subtitle: Text('Time: ${nextReminder!['time']}'),
                      trailing: nextReminder!['audioUrl'] != null &&
                              (nextReminder!['audioUrl'] as String).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () => playAudio(nextReminder!['audioUrl']),
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildTiles(context),
                const SizedBox(height: 24),
                _chatbotCard(),
                const SizedBox(height: 24),
                const Text('Memory Vault', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _memoryVaultScroll(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/patientNotifications', arguments: {
              'patientId': widget.patientId,
              'idToken': widget.idToken,
              'patientName': widget.patientName,
            });
          } else if (index == 2) {
            Navigator.pushNamed(context, '/patientSettings', arguments: {
              'patientId': widget.patientId,
              'idToken': widget.idToken,
              'patientName': widget.patientName,
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _chatbotCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chatbot',
          arguments: {
            'patientId': widget.patientId,
          },
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFF6B6B),
                child: Icon(Icons.mic, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Ask the Assistant",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiles(BuildContext context) {
  final List<Map<String, dynamic>> tiles = [
    {
      'label': 'Reminders',
      'icon': Icons.calendar_today,
      'onTap': () {
        Navigator.pushNamed(
          context,
          '/patientReminders',
          arguments: {
            'patientId': widget.patientId,
            'idToken': widget.idToken,
            'caregiverEmail': caregiverEmail,
          },
        );
      }
    },
    
    {
      'label': 'Memory Vault',
      'icon': Icons.photo_album,
      'onTap': () {
        Navigator.pushNamed(
          context,
          '/memoryVault',
          arguments: {
            'patientId': widget.patientId,
            'idToken': widget.idToken,
          },
        );
      }
    },
    
    
  ];

  return Wrap(
    spacing: 16,
    runSpacing: 16,
    children: tiles.map((tile) {
      return GestureDetector(
        onTap: tile['onTap'] as void Function(),
        child: Container(
          width: MediaQuery.of(context).size.width / 2 - 28,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile['icon'] as IconData, size: 28, color: Colors.black87),
              const SizedBox(height: 8),
              Text(tile['label'] as String, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }).toList(),
  );
 }

  Widget _memoryVaultScroll(BuildContext context) {
    return FutureBuilder<http.Response>(
      future: http.get(
        Uri.parse(
            'https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/patients/${widget.patientId}/memoryVault'),
        headers: {
          'Authorization': 'Bearer ${widget.idToken}',
          'Content-Type': 'application/json',
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return shimmerLoading();
        }

        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return const Text("Failed to load memories");
        }

        final data = jsonDecode(snapshot.data!.body);
        final docs = data['documents'] ?? [];

        final memoryItems = docs.map<Map<String, dynamic>>((doc) {
          final fields = doc['fields'] ?? {};
          return {
            'image': fields['url']?['stringValue'] ?? '',
            'label': fields['title']?['stringValue'] ?? '',
          };
        }).toList();

        if (memoryItems.isEmpty) {
          return const SizedBox(height: 300, child: Text('No memory images found.'));
        }

        final previewItems = memoryItems.take(20).toList();

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: previewItems.length,
            padding: const EdgeInsets.only(right: 8),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final item = previewItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/memoryVault',
                    arguments: {
                      'patientId': widget.patientId,
                      'idToken': widget.idToken,
                    },
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item['image']!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return shimmerTile();
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['label']!,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget shimmerLoading() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => shimmerTile(),
      ),
    );
  }

  Widget shimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
