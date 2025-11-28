import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreService {
  static const String projectId = 'dementia-care-9bbf2'; // e.g. dementia-care-app
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<Map<String, dynamic>> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    required String idToken,
  }) async {
    final url = '$baseUrl/$collection';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "fields": _mapToFirestoreFields(data),
      }),
    );

    return jsonDecode(response.body);
  }

    Future<Map<String, dynamic>> getDocument({
    required String collection,
    required String documentId,
    required String idToken,
  }) async {
    final url = '$baseUrl/$collection/$documentId';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    required String idToken,
  }) async {
    final url = '$baseUrl/$collection/$documentId?updateMask.fieldPaths=email&updateMask.fieldPaths=role';
    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "fields": _mapToFirestoreFields(data),
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteDocument({
    required String collection,
    required String documentId,
    required String idToken,
  }) async {
    final url = '$baseUrl/$collection/$documentId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    return {
      "status": response.statusCode,
      "message": response.statusCode == 200 ? "Deleted successfully" : response.body,
    };
  }


  Map<String, dynamic> _mapToFirestoreFields(Map<String, dynamic> data) {
    final Map<String, dynamic> fields = {};
    data.forEach((key, value) {
      if (value is String) {
        fields[key] = {"stringValue": value};
      } else if (value is int) {
        fields[key] = {"integerValue": value.toString()};
      } else if (value is bool) {
        fields[key] = {"booleanValue": value};
      } else {
        fields[key] = {"stringValue": value.toString()};
      }
    });
    return fields;
  }
}
