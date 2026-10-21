import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AktiviteService {
  static const String baseUrl = 'https://crmapi.ersayerp.com.tr';

  static Future<AktiviteListResult> getAktiviteler({
    int? cariId,
    String? durum,
    String? aktiviteTipi,
    DateTime? baslangicTarihFrom,
    DateTime? baslangicTarihTo,
    int? sorumluUserId,
    int sayfa = 1,
    int sayfaBoyutu = 20,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) {
      return AktiviteListResult(
        success: false,
        errorMessage: 'Oturum bulunamadı',
      );
    }

    final queryParams = {
      'Sayfa': sayfa.toString(),
      'SayfaBoyutu': sayfaBoyutu.toString(),
      if (cariId != null) 'CariId': cariId.toString(),
      if (durum != null) 'Durum': durum,
      if (aktiviteTipi != null) 'AktiviteTipi': aktiviteTipi,
      if (sorumluUserId != null) 'SorumluUserId': sorumluUserId.toString(),
      if (baslangicTarihFrom != null)
        'BaslangicTarihFrom':
            '${baslangicTarihFrom.year}-${baslangicTarihFrom.month.toString().padLeft(2, '0')}-${baslangicTarihFrom.day.toString().padLeft(2, '0')}',
      if (baslangicTarihTo != null)
        'BaslangicTarihTo':
            '${baslangicTarihTo.year}-${baslangicTarihTo.month.toString().padLeft(2, '0')}-${baslangicTarihTo.day.toString().padLeft(2, '0')}',
    };

    final url = Uri.parse(
      '$baseUrl/api/Aktiviteler',
    ).replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = (data['Items'] as List)
          .map((e) => AktiviteModel.fromJson(e))
          .toList();
      return AktiviteListResult(
        success: true,
        items: items,
        toplamKayit: data['ToplamKayit'],
        toplamSayfa: data['ToplamSayfa'],
      );
    }
    if (response.statusCode == 401) {
      return AktiviteListResult(
        success: false,
        errorMessage: 'Oturum süresi doldu',
      );
    }
    return AktiviteListResult(success: false, errorMessage: 'Bir hata oluştu');
  }

  static Future<AktiviteDetayModel?> getAktiviteDetay(int id) async {
    final token = await StorageService.getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/api/Aktiviteler/$id');
    final response = await http.get(
      url,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return AktiviteDetayModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<bool> aktiviteKaydet({
    int? cariId,
    required String konu,
    String? aciklama,
    required String aktiviteTipi,
    required DateTime baslangicTarihi,
    DateTime? bitisTarihi,
    required String durum,
    int? sorumluUserId,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/Aktiviteler');

    final body = {
      if (cariId != null) 'CariId': cariId,
      'Konu': konu,
      if (aciklama != null) 'Aciklama': aciklama,
      'AktiviteTipi': aktiviteTipi,
      'BaslangicTarihi': baslangicTarihi.toUtc().toIso8601String(),
      if (bitisTarihi != null)
        'BitisTarihi': bitisTarihi.toUtc().toIso8601String(),
      'Durum': durum,
      if (sorumluUserId != null) 'SorumluUserId': sorumluUserId,
    };

    print('=== AKTİVİTE KAYDET ===');
    print('BODY: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> aktiviteGuncelle({
    required int id,
    int? cariId,
    required String konu,
    String? aciklama,
    required String aktiviteTipi,
    required DateTime baslangicTarihi,
    DateTime? bitisTarihi,
    required String durum,
    int? sorumluUserId,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/Aktiviteler/$id');

    final body = {
      if (cariId != null) 'CariId': cariId,
      'Konu': konu,
      if (aciklama != null) 'Aciklama': aciklama,
      'AktiviteTipi': aktiviteTipi,
      'BaslangicTarihi': baslangicTarihi.toUtc().toIso8601String(),
      if (bitisTarihi != null)
        'BitisTarihi': bitisTarihi.toUtc().toIso8601String(),
      'Durum': durum,
      if (sorumluUserId != null) 'SorumluUserId': sorumluUserId,
    };

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  static Future<bool> aktiviteSil(int id) async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/Aktiviteler/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<List<CariAramaModel>> cariAra(String arama) async {
    final token = await StorageService.getToken();
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/api/Cariler').replace(
      queryParameters: {
        'Arama': arama,
        'Aktif': 'true',
        'SayfaBoyutu': '10',
        'Sayfa': '1',
      },
    );

    final response = await http.get(
      url,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['Items'] as List)
          .map((e) => CariAramaModel.fromJson(e))
          .toList();
    }
    return [];
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class AktiviteModel {
  final int id;
  final int? cariId;
  final String? cariUnvan;
  final String konu;
  final String aktiviteTipi;
  final DateTime baslangicTarihi;
  final DateTime? bitisTarihi;
  final String durum;
  final String? sorumluAdSoyad;

  AktiviteModel({
    required this.id,
    this.cariId,
    this.cariUnvan,
    required this.konu,
    required this.aktiviteTipi,
    required this.baslangicTarihi,
    this.bitisTarihi,
    required this.durum,
    this.sorumluAdSoyad,
  });

  factory AktiviteModel.fromJson(Map<String, dynamic> json) => AktiviteModel(
    id: json['Id'],
    cariId: json['CariId'],
    cariUnvan: json['CariUnvan'],
    konu: json['Konu'],
    aktiviteTipi: json['AktiviteTipi'],
    baslangicTarihi: DateTime.parse(json['BaslangicTarihi']),
    bitisTarihi: json['BitisTarihi'] != null
        ? DateTime.parse(json['BitisTarihi'])
        : null,
    durum: json['Durum'],
    sorumluAdSoyad: json['SorumluAdSoyad'],
  );
}

class AktiviteDetayModel extends AktiviteModel {
  final String? aciklama;
  final String? olusturanAdSoyad;
  final DateTime olusturmaTarihi;

  AktiviteDetayModel({
    required super.id,
    super.cariId,
    super.cariUnvan,
    required super.konu,
    required super.aktiviteTipi,
    required super.baslangicTarihi,
    super.bitisTarihi,
    required super.durum,
    super.sorumluAdSoyad,
    this.aciklama,
    this.olusturanAdSoyad,
    required this.olusturmaTarihi,
  });

  factory AktiviteDetayModel.fromJson(Map<String, dynamic> json) =>
      AktiviteDetayModel(
        id: json['Id'],
        cariId: json['CariId'],
        cariUnvan: json['CariUnvan'],
        konu: json['Konu'],
        aktiviteTipi: json['AktiviteTipi'],
        baslangicTarihi: DateTime.parse(json['BaslangicTarihi']),
        bitisTarihi: json['BitisTarihi'] != null
            ? DateTime.parse(json['BitisTarihi'])
            : null,
        durum: json['Durum'],
        sorumluAdSoyad: json['SorumluAdSoyad'],
        aciklama: json['Aciklama'],
        olusturanAdSoyad: json['OlusturanAdSoyad'],
        olusturmaTarihi: DateTime.parse(json['OlusturmaTarihi']),
      );
}

class CariAramaModel {
  final int id;
  final String unvan;
  final String cariKod;

  CariAramaModel({
    required this.id,
    required this.unvan,
    required this.cariKod,
  });

  factory CariAramaModel.fromJson(Map<String, dynamic> json) => CariAramaModel(
    id: json['Id'],
    unvan: json['Unvan'],
    cariKod: json['CariKod'],
  );
}

class AktiviteListResult {
  final bool success;
  final List<AktiviteModel> items;
  final int toplamKayit;
  final int toplamSayfa;
  final String? errorMessage;

  AktiviteListResult({
    required this.success,
    this.items = const [],
    this.toplamKayit = 0,
    this.toplamSayfa = 0,
    this.errorMessage,
  });
}
