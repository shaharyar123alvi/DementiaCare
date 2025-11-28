import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FirebaseStorageService {
  final String bucket = 'YOUR_FIREBASE_PROJECT_ID.appspot.com'; // Change this
  final String baseUrl = 'https://firebasestorage.googleapis.com/v0/b';

  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String pathInStorage,
    required String idToken,
    required String contentType,
  }) async {
    final url =
        '$baseUrl/$bucket/o?uploadType=media&name=$pathInStorage';

    final bytes = await file.readAsBytes();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final downloadToken = jsonDecode(response.body)['downloadTokens'];
      final downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(pathInStorage)}?alt=media&token=$downloadToken';

      return {
        'success': true,
        'downloadUrl': downloadUrl,
      };
    } else {
      return {
        'success': false,
        'message': response.body,
        'status': response.statusCode,
      };
    }
  }
}
