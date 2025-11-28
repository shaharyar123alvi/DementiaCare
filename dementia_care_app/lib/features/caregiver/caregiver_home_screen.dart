import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';


class CaregiverHomeScreen extends StatefulWidget {
  final String patientId;
  final String idToken;
  //  add this

  const CaregiverHomeScreen({
    super.key,
    required this.patientId,
    required this.idToken,
    
  });

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}



class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {

 String? patientName;
  bool _loadingName = true;

  @override
void initState() {
    super.initState();
    fetchPatientName(); // call function on load
  }

 Future<void> fetchPatientName() async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/patients/${widget.patientId}',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.idToken}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fields = data['fields'] ?? {};
      setState(() {
        patientName = fields['name']?['stringValue'] ?? 'Patient';
        _loadingName = false;
      });
    } else {
      setState(() {
        patientName = 'Patient';
        _loadingName = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Welcome to Nuera!",
          style: TextStyle(
            color: Color(0xFF607D8B),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 40,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFDFD), Color(0xFFFFF1F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle("Patient View"),
              const SizedBox(height: 12),
              _quickActionRow(),
              const SizedBox(height: 24),
              _sectionTitle("Patient Details"),
              const SizedBox(height: 12),
              _patientDetailsCard(),
              const SizedBox(height: 24),
              _sectionTitle("Patient Activities"),
              const SizedBox(height: 12),
              _activityRow(context),
              const SizedBox(height: 24),
              _sectionTitle(
                "Memory Vault",
                action: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/memoryVault',
                      arguments: {
                        'patientId': widget.patientId,
                        'idToken': widget.idToken,
                      },
                    );
                  },
                  child: const Text("See All", style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 12),
              _memoryVaultScroll(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 90, 117, 131),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/caregiverHome');
              break;
            case 1:
              Navigator.pushNamed(
                context,
                '/caregiverSettings',
                arguments: {
                  'patientId': widget.patientId,
                  'idToken': widget.idToken,
                },
              );
              break;
            case 2:
              Navigator.pushNamed(
                context,
                '/notification',
                arguments: {
                  'patientId': widget.patientId,
                  'idToken': widget.idToken,
                },
              );
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF607D8B),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _quickActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _patientAccessCard(),
        const SizedBox(height: 20),
      ],
    );
  }
  

  Widget _buildActionTile(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEFEFEF),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }


Widget _patientAccessCard() {
  return GestureDetector(
    onTap: () {
      if (!_loadingName && patientName != null) {
        Navigator.pushNamed(context, '/patientHome', arguments: {
          'patientId': widget.patientId,
          'idToken': widget.idToken,
          'patientName': patientName,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loading patient name, please wait...")),
        );
      }
    },
    child: Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFECE9E6), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_forward_ios, color: Colors.black),
              const SizedBox(width: 30),
              const CircleAvatar(
            backgroundColor: Colors.black,
            radius: 18,
            child: Icon(Icons.person_3_outlined, color: Colors.white),
          ),
              Text(
                "      Switch to Patient View    ",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF607D8B)),
              ),
            ],
          ),
          
        ],
      ),
    ),
  );
}



  Widget _patientDetailsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/patientDetails', arguments: {
          'patientId': widget.patientId,
          'idToken': widget.idToken,
        });
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/PatientD.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              
              Icon(Icons.arrow_forward_ios, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEAEAEA),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActivityTile(
          icon: Icons.medication,
          label: 'Medications',
          onTap: () {
            Navigator.pushNamed(context, '/medications', arguments: {
              'patientId': widget.patientId,
              'idToken': widget.idToken,
            });
          },
        ),
        _buildActivityTile(
          icon: Icons.access_alarm,
          label: 'Reminders',
          onTap: () {
            Navigator.pushNamed(context, '/reminders', arguments: {
              'patientId': widget.patientId,
              'idToken': widget.idToken,
            });
          },
        ),
        _buildActivityTile(
          icon: Icons.calendar_today,
          label: 'Apointment',
          onTap: () {
            Navigator.pushNamed(context, '/appointments', arguments: {
              'patientId': widget.patientId,
              'idToken': widget.idToken,
            });
          },
        ),
        _buildActivityTile(
          icon: Icons.monitor_heart,
          label: 'Monitoring',
          onTap: () {
           Navigator.pushNamed(context, '/patientMonitoring', arguments: {
            'patientId': widget.patientId,
            'idToken': widget.idToken,
          });
          },
        ),
      ],
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
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Shimmer.fromColors(
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
            ),
          ),
        );
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
        return const SizedBox(height: 100, child: Text('No memory images found.'));
      }

      final previewItems = memoryItems.take(20).toList(); // lazy-load up to 20

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
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
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
}
