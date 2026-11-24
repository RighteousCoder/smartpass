import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.223:5000';

  // Get the current user's Firebase login token
  static Future<String?> getToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return await user.getIdToken();
  }

  // Test communication with the protected backend
  static Future<void> testConnection() async {
    final token = await getToken();

    if (token == null) {
      print('No logged-in Firebase user found.');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/protected'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Backend response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Backend authentication successful: ${data['message']}');
    } else {
      print('Backend authentication failed: ${response.statusCode}');
    }
  }
}