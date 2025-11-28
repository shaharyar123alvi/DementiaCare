import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseAuthService {
  static const String _apiKey = 'AIzaSyBPJMuBHvwiFf55gj3HP6zgkcZ0KkNLZJs';

  static const String _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';

  static const String _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse(_signUpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse(_signInUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'error': jsonDecode(response.body)};
    }
  }
}
