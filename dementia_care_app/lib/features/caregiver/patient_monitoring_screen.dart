import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class PatientMonitoringScreen extends StatefulWidget {
  final String patientId;
  final String idToken;

  const PatientMonitoringScreen({
    required this.patientId,
    required this.idToken,
  });

  @override
  _PatientMonitoringScreenState createState() => _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState extends State<PatientMonitoringScreen> {
  double adherencePercent = 0;
  List<Map<String, dynamic>> missedReminders = [];
  List<Map<String, dynamic>> upcomingReminders = [];
  List<Map<String, dynamic>> activityLog = [];
  List<String> memoryImages = [];
  Map<String, double> adherenceOverTime = {};
  List<String> topMissedMedications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMonitoringData();
  }
Future<void> loadMonitoringData() async {
  final headers = {
    'Authorization': 'Bearer ${widget.idToken}',
  };
  final patientId = widget.patientId;

  try {
    final trackingRes = await http.get(
      Uri.parse('https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/reminderTracking'),
      headers: headers,
    );

    final remindersRes = await http.get(
      Uri.parse('https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/reminders'),
      headers: headers,
    );

    final memoryVaultRes = await http.get(
      Uri.parse('https://firestore.googleapis.com/v1/projects/dementia-care-9bbf2/databases/(default)/documents/patients/$patientId/memoryVault?pageSize=5'),
      headers: headers,
    );

    if (trackingRes.statusCode == 200 &&
        remindersRes.statusCode == 200 &&
        memoryVaultRes.statusCode == 200) {
      final allTrackingDocs = (jsonDecode(trackingRes.body)['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final allReminderDocs = (jsonDecode(remindersRes.body)['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final memoryDocs = (jsonDecode(memoryVaultRes.body)['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final trackDocs = allTrackingDocs.where((doc) =>
        doc['fields']?['patientId']?['stringValue'] == patientId).toList();

      final reminderDocs = allReminderDocs.where((doc) =>
        doc['fields']?['patientId']?['stringValue'] == patientId).toList();

      Map<String, int> dailyTotal = {};
      Map<String, int> dailyConfirmed = {};
      Map<String, int> missedMedicationCount = {};

      for (var doc in reminderDocs) {
        final name = doc['fields']?['name']?['stringValue'] ?? 'Unnamed';
        final timeStr = doc['fields']?['time']?['stringValue'];
        final date = DateTime.tryParse(timeStr ?? '')?.toIso8601String().substring(0, 10);
        if (date != null) {
          dailyTotal[date] = (dailyTotal[date] ?? 0) + 1;
        }
      }

      for (var doc in trackDocs) {
        final ts = doc['fields']?['actualTime']?['timestampValue'];
        final date = DateTime.tryParse(ts ?? '')?.toIso8601String().substring(0, 10);
        if (date != null) {
          dailyConfirmed[date] = (dailyConfirmed[date] ?? 0) + 1;
        }
      }

      for (var doc in reminderDocs) {
        final reminderTimeStr = doc['fields']?['time']?['stringValue'];
        final reminderTime = DateTime.tryParse(reminderTimeStr ?? '');
        final now = DateTime.now();
        final docId = doc['name'].split('/').last;
        final name = doc['fields']?['name']?['stringValue'] ?? 'Unnamed';

        final wasMissed = reminderTime != null &&
            now.difference(reminderTime).inHours > 24 &&
            !trackDocs.any((track) =>
              track['fields']?['reminderId']?['stringValue'] == docId);

        if (wasMissed) {
          missedMedicationCount[name] = (missedMedicationCount[name] ?? 0) + 1;
        }
      }

      final adherenceMap = <String, double>{};
      for (var date in dailyTotal.keys) {
        final total = dailyTotal[date] ?? 1;
        final confirmed = dailyConfirmed[date] ?? 0;
        adherenceMap[date] = confirmed / total;
      }

      final confirmedCount = trackDocs.length;
      final totalCount = reminderDocs.length;
      final ratio = totalCount > 0 ? confirmedCount / totalCount : 0;

      final sortedMissed = missedMedicationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = sortedMissed.take(3).map((e) => e.key).toList();

      print("📊 Adherence Over Time Map: $adherenceMap");
      print("🔥 Top Missed Meds: $top3");

      setState(() {
        adherencePercent = ratio.toDouble().clamp(0.0, 1.0);
        adherenceOverTime = adherenceMap;
        topMissedMedications = top3;

        missedReminders = reminderDocs.where((doc) {
          final reminderTime = DateTime.tryParse(doc['fields']?['time']?['stringValue'] ?? '');
          final now = DateTime.now();
          final docId = doc['name'].split('/').last;
          return reminderTime != null &&
              now.difference(reminderTime).inHours > 24 &&
              !trackDocs.any((track) =>
                track['fields']?['reminderId']?['stringValue'] == docId);
        }).map((e) => {
              'name': e['fields']?['name']?['stringValue'] ?? '',
              'time': e['fields']?['time']?['stringValue'] ?? '',
            }).toList();

        upcomingReminders = reminderDocs.where((doc) {
          final time = DateTime.tryParse(doc['fields']?['time']?['stringValue'] ?? '');
          final now = DateTime.now();
          return time != null && (time.isAfter(now) || time.day == now.day);
        }).take(3).map((e) => {
              'name': e['fields']?['name']?['stringValue'] ?? '',
              'time': e['fields']?['time']?['stringValue'] ?? '',
            }).toList();

        activityLog = trackDocs.take(5).map((e) => {
              'name': e['fields']?['reminderName']?['stringValue'] ?? '',
              'doneAt': e['fields']?['actualTime']?['timestampValue'] ?? '',
            }).toList();

        memoryImages = memoryDocs.map<String>((e) =>
          e['fields']?['url']?['stringValue'] ?? '').toList();

        isLoading = false;
      });
    }
  } catch (e) {
    print('❌ Error loading monitoring data: $e');
    setState(() => isLoading = false);
  }
}




  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
      child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget adherenceChart() {
    final entries = adherenceOverTime.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: entries.asMap().entries.map((e) => FlSpot(
                e.key.toDouble(),
                (e.value.value * 100).clamp(0, 100),
              )).toList(),
              isCurved: true,
              barWidth: 3,
              color: Colors.black,
              belowBarData: BarAreaData(show: false),
            )
          ],
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }

  Widget loadingShimmer() => Center(child: CircularProgressIndicator());

  @override
  Widget build(BuildContext context) {
    final emojiFeedback = adherencePercent > 0.8 ? "Keep it up! 🎉" : adherencePercent > 0.5 ? "Doing okay! 👍" : "Let's try harder 💪";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Patient Monitoring", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? loadingShimmer()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Adherence Overview"),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: adherencePercent,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                        Text("${(adherencePercent * 100).toStringAsFixed(0)}%",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(emojiFeedback, style: TextStyle(fontSize: 16)),
                  )),
                  adherenceChart(),

                  sectionTitle("Top Missed Medications"),
                  ...topMissedMedications.map((e) => ListTile(
                        leading: Icon(Icons.medication, color: Colors.red),
                        title: Text(e),
                      )),
                  sectionTitle("Missed Reminders"),
                  ...missedReminders.map((e) => ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text(e['name']),
                        subtitle: Text("Missed: ${DateTime.parse(e['time']).toLocal()}"),
                      )),
                  sectionTitle("Upcoming Schedule"),
                  ...upcomingReminders.map((e) => ListTile(
                        leading: Icon(Icons.schedule),
                        title: Text(e['name']),
                        subtitle: Text("At: ${DateTime.parse(e['time']).toLocal()}"),
                      )),
                  sectionTitle("Recent Activity"),
                  ...activityLog.map((e) => ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text(e['name']),
                        subtitle: Text("Done at: ${DateTime.parse(e['doneAt']).toLocal()}"),
                      )),
                
                ],
              ),
            ),
    );
  }
}
