import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class CariService {
  static const String baseUrl = 'https://crmapi.ersayerp.com.tr';

  static Future<CariListResult> getCariler({
    String? arama,
    bool? aktif = true,
    int sayfa = 1,
    int sayfaBoyutu = 20,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) {
      return CariListResult(success: false, errorMessage: 'Oturum bulunamadı');
    }

    final queryParams = {
      'Sayfa': sayfa.toString(),
      'SayfaBoyutu': sayfaBoyutu.toString(),
      if (aktif != null) 'Aktif': aktif.toString(),
      if (arama != null && arama.isNotEmpty) 'Arama': arama,
    };

    final url = Uri.parse(
      '$baseUrl/api/Cariler',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = (data['Items'] as List)
          .map((e) => CariModel.fromJson(e))
          .toList();
      return CariListResult(
        success: true,
        items: items,
        toplamKayit: data['ToplamKayit'],
        toplamSayfa: data['ToplamSayfa'],
      );
    }

    if (response.statusCode == 401) {
      return CariListResult(
        success: false,
        errorMessage: 'Oturum süresi doldu',
      );
    }

    return CariListResult(success: false, errorMessage: 'Bir hata oluştu');
  }

  static Future<List<CariTemsilciModel>> getTemsilciler(int cariId) async {
    final token = await StorageService.getToken();
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/api/Cariler/$cariId/temsilciler');
    final response = await http.get(
      url,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => CariTemsilciModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> cariKaydet({
    required String unvan,
    String? yetkiliKisi,
    String? email,
    String? telefon,
    String? gsm,
    String? adres,
    String? il,
    String? ilce,
    String? vergiDairesi,
    String? vergiNo,
    String cariTipi = 'musteri',
    String? cariTemsilcisi,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/api/Cariler');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'Unvan': unvan,
        if (yetkiliKisi != null) 'YetkiliKisi': yetkiliKisi,
        if (email != null) 'Email': email,
        if (telefon != null) 'Telefon': telefon,
        if (gsm != null) 'Gsm': gsm,
        if (adres != null) 'Adres': adres,
        if (il != null) 'Il': il,
        if (ilce != null) 'Ilce': ilce,
        if (vergiDairesi != null) 'VergiDairesi': vergiDairesi,
        if (vergiNo != null) 'VergiNo': vergiNo,
        'CariTipi': cariTipi,
        if (cariTemsilcisi != null) 'CariTemsilcisi': cariTemsilcisi,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<bool> temsilciKaydet({
    required int cariId,
    required String adSoyad,
    String? telefon,
    String? gsm,
    String? email,
    String? pozisyon,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/Cariler/$cariId/temsilciler');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'AdSoyad': adSoyad,
        if (telefon != null) 'Telefon': telefon,
        if (gsm != null) 'Gsm': gsm,
        if (email != null) 'Email': email,
        if (pozisyon != null) 'Pozisyon': pozisyon,
      }),
    );

    return response.statusCode == 200;
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class CariModel {
  final int id;
  final String cariKod;
  final String unvan;
  final String? yetkiliKisi;
  final String? telefon;
  final String? gsm;
  final String? email;
  final String? il;
  final String? ilce;
  final String? adres;
  final String cariTipi;
  final String aramaDurumu;
  final bool aktif;

  CariModel({
    required this.id,
    required this.cariKod,
    required this.unvan,
    this.yetkiliKisi,
    this.telefon,
    this.gsm,
    this.email,
    this.il,
    this.ilce,
    this.adres,
    required this.cariTipi,
    required this.aramaDurumu,
    required this.aktif,
  });

  factory CariModel.fromJson(Map<String, dynamic> json) => CariModel(
    id: json['Id'],
    cariKod: json['CariKod'],
    unvan: json['Unvan'],
    yetkiliKisi: json['YetkiliKisi'],
    telefon: json['Telefon'],
    gsm: json['Gsm'],
    email: json['Email'],
    il: json['Il'],
    ilce: json['Ilce'],
    adres: json['AnaAdres'],
    cariTipi: json['CariTipi'],
    aramaDurumu: json['AramaDurumu'],
    aktif: json['Aktif'],
  );

  String get shortName {
    final words = unvan.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return unvan.substring(0, _min(2, unvan.length)).toUpperCase();
  }

  int _min(int a, int b) => a < b ? a : b;
}

class CariTemsilciModel {
  final int id;
  final String adSoyad;
  final String? telefon;
  final String? gsm;
  final String? email;
  final String? pozisyon;

  CariTemsilciModel({
    required this.id,
    required this.adSoyad,
    this.telefon,
    this.gsm,
    this.email,
    this.pozisyon,
  });

  factory CariTemsilciModel.fromJson(Map<String, dynamic> json) =>
      CariTemsilciModel(
        id: json['Id'],
        adSoyad: json['AdSoyad'],
        telefon: json['Telefon'],
        gsm: json['Gsm'],
        email: json['Email'],
        pozisyon: json['Pozisyon'],
      );
}

class CariListResult {
  final bool success;
  final List<CariModel> items;
  final int toplamKayit;
  final int toplamSayfa;
  final String? errorMessage;

  CariListResult({
    required this.success,
    this.items = const [],
    this.toplamKayit = 0,
    this.toplamSayfa = 0,
    this.errorMessage,
  });
}
