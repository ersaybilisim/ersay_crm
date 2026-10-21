import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class FcmService {
  static const String baseUrl = 'https://crmapi.ersayerp.com.tr/api';

  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      final jwt = await StorageService.getToken();

      if (jwt == null) {
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/FcmToken/kaydet'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token, 'platform': 'android'}),
      );

      print('FCM REGISTER STATUS: ${response.statusCode}');
      print(response.body);
    } catch (e) {
      print('FCM REGISTER ERROR: $e');
    }
  }
}
