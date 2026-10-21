import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class MasrafService {
  static const String baseUrl = 'https://crmapi.ersayerp.com.tr/api';

  static Future<List<dynamic>> getMasraflar() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/Masraflar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) return decoded;

      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }

      return [];
    }

    throw Exception('Masraflar alınamadı. Kod: ${response.statusCode}');
  }

  static Future<void> masrafGuncelle({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/Masraflar/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Masraf güncellenemedi. Kod: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<void> masrafSil({required int id}) async {
    final token = await StorageService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/Masraflar/$id'),
      headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      throw Exception(
        'Masraf silinemedi. Kod: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<void> belgeYukle({
    required int masrafId,
    required File file,
  }) async {
    final token = await StorageService.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/Masraflar/$masrafId/belge-yukle'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Fiş görseli yüklenemedi. Kod: ${response.statusCode} - $responseBody',
      );
    }
  }

  static Future<Map<String, dynamic>> masrafEkle({
    required Map<String, dynamic> body,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/Masraflar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Masraf kaydedilemedi. Kod: ${response.statusCode} - ${response.body}',
    );
  }

  static String? belgeUrlFromItem(dynamic item) {
    if (item == null) return null;

    final value =
        item['BelgeYolu'] ??
        item['belgeYolu'] ??
        item['BelgeDosyaYolu'] ??
        item['belgeDosyaYolu'] ??
        item['BelgeDosyaAdi'] ??
        item['belgeDosyaAdi'] ??
        item['belgeUrl'] ??
        item['BelgeUrl'] ??
        item['dosyaYolu'] ??
        item['DosyaYolu'] ??
        item['fisResmi'] ??
        item['FisResmi'] ??
        item['resimUrl'] ??
        item['ResimUrl'];

    if (value == null || value.toString().trim().isEmpty) return null;

    var text = value.toString().trim();

    text = text.replaceAll(r'\', '/');

    final fileName = text.split('/').last;

    if (text.startsWith('http')) return text;

    return 'https://crmapi.ersayerp.com.tr/uploads/Masraflar/$fileName';
  }
}
