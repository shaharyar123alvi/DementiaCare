import 'package:flutter/material.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/caregiver/patient_list_screen.dart';
import 'features/caregiver/add_patient_screen.dart';
import 'features/caregiver/caregiver_home_screen.dart';
import 'features/patient/patient_home_screen.dart';
import 'features/memory_vault/memory_vault_screen.dart';
import 'features/caregiver/patient_details_screen.dart';
import 'features/caregiver/medications_screen.dart';
import 'features/caregiver/patient_monitoring_screen.dart';
import 'features/caregiver/reminders_screen.dart';
import 'features/caregiver/caregiver_notifications_screen.dart';
import 'features/caregiver/caregiver_profile.dart';
import 'features/caregiver/caregiver_settings_screen.dart';
import 'features/caregiver/appointments_screen.dart';
import 'features/patient/patient_reminders_screen.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'features/auth/forgot_password_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dementia Care App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SanFrancisco',
        useMaterial3: true,
      ),
      initialRoute: '/signup',
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/patientList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return PatientListScreen(
            caregiverEmail: args['email'],
            idToken: args['idToken'],
          );
        },
        '/addPatient': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AddPatientScreen(
            caregiverEmail: args['caregiverEmail'],
            idToken: args['idToken'],
          );
        },
        '/caregiverHome': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CaregiverHomeScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/addMemoryVault': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return MemoryVaultScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/patientDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return PatientDetailsScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/medications': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return MedicationsScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/reminders': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return RemindersScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/appointments': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AppointmentsScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/notification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return CaregiverNotificationScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/caregiverSettings': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return CaregiverSettingsScreen(idToken: args['idToken']);
        },
        '/memoryVault': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemoryVaultScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },
        '/patientHome': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatientHomeScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
            patientName: args['patientName'],
          );
        },
        '/patientReminders': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatientRemindersScreen(
            patientId: args['patientId'],
            caregiverEmail: args['caregiverEmail'],
            idToken: args['idToken'],
          );
        },
        '/chatbot': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatientChatbotScreen(patientId: args['patientId']);
        },

        // ✅ NEWLY ADDED PATIENT MONITORING ROUTE
        '/patientMonitoring': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatientMonitoringScreen(
            patientId: args['patientId'],
            idToken: args['idToken'],
          );
        },

        '/forgotPassword': (context) => const ForgotPasswordScreen(),







        
      },
    );
  }
}
