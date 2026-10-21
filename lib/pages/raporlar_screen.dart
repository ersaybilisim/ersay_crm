import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/aktivite_service.dart';
import '../services/storage_service.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class RaporlarScreen extends StatefulWidget {
  const RaporlarScreen({super.key});

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  @override
  State<RaporlarScreen> createState() => _RaporlarScreenState();
}

class _KullaniciModel {
  final int id;
  final String adSoyad;
  const _KullaniciModel({required this.id, required this.adSoyad});
}

class _RaporlarScreenState extends State<RaporlarScreen> {
  bool isLoading = true;
  bool isAdmin = false;
  int? mevcutUserId;
  String? mevcutUserAdSoyad;

  // Admin kullanıcı seçimi
  List<_KullaniciModel> kullanicilar = [];
  _KullaniciModel? seciliKullanici; // null = tümü

  DateTime baslangicTarihi = DateTime.now().subtract(const Duration(days: 30));
  DateTime bitisTarihi = DateTime.now();

  late DateTime ayBaslangic;
  late DateTime ayBitis;

  int toplamAktivite = 0;
  int tamamlanan = 0;
  int devamEden = 0;
  int teklifVerilen = 0;
  int planli = 0;

  static const int kpi1Hedef = 20;
  static const int kpi2Hedef = 5;

  int kpi1Gerceklesen = 0;
  int kpi2Nitelikli = 0;

  Map<String, int> tipDagilim = {};
  Map<String, int> durumDagilim = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    ayBaslangic = DateTime(now.year, now.month, 1);
    ayBitis = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _init();
  }

  Future<void> _init() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    final parts = token.split('.');
    if (parts.length == 3) {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      final rol =
          data['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          data['role'] ??
          '';
      final idStr =
          data['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          data['sub'] ??
          '';
      final adSoyad = data['AdSoyad'] ?? '';

      setState(() {
        isAdmin = rol.toString().toLowerCase() == 'admin';
        mevcutUserId = int.tryParse(idStr.toString());
        mevcutUserAdSoyad = adSoyad.toString();
      });

      if (isAdmin) await _loadKullanicilar(token);
    }

    await Future.wait([_loadRapor(), _loadKpi()]);
  }

  Future<void> _loadKullanicilar(String token) async {
    try {
      final url = Uri.parse(
        'https://crmapi.ersayerp.com.tr/api/Lookup/kullanicilar',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        setState(() {
          kullanicilar = list
              .map((e) => _KullaniciModel(id: e['Id'], adSoyad: e['AdSoyad']))
              .toList();
        });
      }
    } catch (_) {}
  }

  int? get _filtreleEdecegiUserId {
    if (isAdmin) {
      return seciliKullanici?.id; // null ise tümü
    }
    return mevcutUserId; // normal kullanıcı sadece kendini görür
  }

  Future<void> _loadRapor() async {
    final result = await AktiviteService.getAktiviteler(
      baslangicTarihFrom: DateTime(
        baslangicTarihi.year,
        baslangicTarihi.month,
        baslangicTarihi.day,
      ),
      baslangicTarihTo: DateTime(
        bitisTarihi.year,
        bitisTarihi.month,
        bitisTarihi.day,
        23,
        59,
        59,
      ),
      sorumluUserId: _filtreleEdecegiUserId,
      sayfaBoyutu: 500,
    );

    if (!mounted) return;

    final liste = result.items;
    final tip = <String, int>{};
    final durum = <String, int>{};
    int tam = 0, dev = 0, tek = 0, pla = 0;

    for (final a in liste) {
      tip[a.aktiviteTipi] = (tip[a.aktiviteTipi] ?? 0) + 1;
      durum[a.durum] = (durum[a.durum] ?? 0) + 1;
      if (a.durum == 'tamamlandi') tam++;
      if (a.durum == 'devam_ediyor') dev++;
      if (a.durum == 'teklif_verildi') tek++;
      if (a.durum == 'planli') pla++;
    }

    setState(() {
      toplamAktivite = liste.length;
      tamamlanan = tam;
      devamEden = dev;
      teklifVerilen = tek;
      planli = pla;
      tipDagilim = tip;
      durumDagilim = durum;
    });
  }

  Future<void> _loadKpi() async {
    final result = await AktiviteService.getAktiviteler(
      baslangicTarihFrom: ayBaslangic,
      baslangicTarihTo: ayBitis,
      sorumluUserId: _filtreleEdecegiUserId,
      sayfaBoyutu: 500,
    );

    if (!mounted) return;

    final gerceklesenListe = result.items.where((a) {
      final durum = a.durum.trim().toLowerCase().replaceAll('ı', 'i');

      return durum != 'planli' && durum != 'iptal';
    }).toList();

    final nitelikli = gerceklesenListe.where((a) {
      final tip = a.aktiviteTipi.trim().toLowerCase();

      return tip == 'toplanti' || tip == 'ziyaret';
    }).length;

    for (final a in result.items) {
      debugPrint('KPI DURUM: [${a.durum}]');
    }

    debugPrint('TOPLAM GELEN: ${result.items.length}');
    debugPrint('GERCEKLESEN SAYILAN: ${gerceklesenListe.length}');

    setState(() {
      kpi1Gerceklesen = gerceklesenListe.length;
      kpi2Nitelikli = nitelikli;
      isLoading = false;
    });
  }

  Future<void> _yenile() async {
    setState(() => isLoading = true);
    await Future.wait([_loadRapor(), _loadKpi()]);
  }

  Future<void> _tarihSec(bool baslangic) async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: baslangic ? baslangicTarihi : bitisTarihi,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr'),
    );
    if (secilen != null) {
      setState(() {
        if (baslangic)
          baslangicTarihi = secilen;
        else
          bitisTarihi = secilen;
      });
      _loadRapor();
    }
  }

  String _formatTarih(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  String _ayAdi(int ay) {
    const aylar = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return aylar[ay];
  }

  String get _baslikMetni {
    if (!isAdmin) return mevcutUserAdSoyad ?? '';
    if (seciliKullanici == null) return 'Tüm personel verileri';
    return seciliKullanici!.adSoyad;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ayBaslik = '${_ayAdi(now.month)} ${now.year}';

    return Scaffold(
      backgroundColor: RaporlarScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _yenile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raporlar',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: RaporlarScreen.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _baslikMetni,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Admin kullanıcı seçimi
                      if (isAdmin) ...[
                        _KullaniciSecimi(
                          kullanicilar: kullanicilar,
                          secili: seciliKullanici,
                          onSecildi: (k) {
                            setState(() => seciliKullanici = k);
                            _yenile();
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      // KPI Başlık
                      Row(
                        children: [
                          const Text(
                            'KPI Göstergeleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: RaporlarScreen.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: RaporlarScreen.yellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ayBaslik,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF856200),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: RaporlarScreen.yellow,
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _KpiKart(
                                baslik: 'Aktivite Yoğunluğu',
                                altBaslik: 'Aylık görüşme hedefi',
                                gerceklesen: kpi1Gerceklesen,
                                hedef: kpi1Hedef,
                                birim: 'görüşme',
                                ikon: Icons.event_note_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiKart(
                                baslik: 'Saha Kalite Oranı',
                                altBaslik: 'Aylık toplantı & ziyaret hedefi',
                                gerceklesen: kpi2Nitelikli,
                                hedef: kpi2Hedef,
                                birim: 'toplantı',
                                ikon: Icons.handshake_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Aktivite Raporu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: RaporlarScreen.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _TarihFiltre(
                          baslangic: baslangicTarihi,
                          bitis: bitisTarihi,
                          onBaslangicSec: () => _tarihSec(true),
                          onBitisSec: () => _tarihSec(false),
                          formatTarih: _formatTarih,
                        ),
                        const SizedBox(height: 20),

                        _OzetKartlar(
                          toplam: toplamAktivite,
                          tamamlanan: tamamlanan,
                          devamEden: devamEden,
                          teklifVerilen: teklifVerilen,
                          planli: planli,
                        ),
                        const SizedBox(height: 24),

                        if (tipDagilim.isNotEmpty) ...[
                          const Text(
                            'Aktivite Tiplerine Göre Dağılım',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: RaporlarScreen.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _TipBarGrafik(tipDagilim: tipDagilim),
                          const SizedBox(height: 24),
                        ],

                        if (durumDagilim.isNotEmpty) ...[
                          const Text(
                            'Durum Dağılımı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: RaporlarScreen.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DurumListesi(
                            durumDagilim: durumDagilim,
                            toplam: toplamAktivite,
                          ),
                        ],

                        if (toplamAktivite == 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE1E1E1),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.bar_chart_outlined,
                                  size: 48,
                                  color: Color(0xFFDDDDDD),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Seçilen tarih aralığında aktivite bulunamadı',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kullanıcı Seçimi (sadece admin) ──────────────────────────────────────────

class _KullaniciSecimi extends StatelessWidget {
  final List<_KullaniciModel> kullanicilar;
  final _KullaniciModel? secili;
  final Function(_KullaniciModel?) onSecildi;

  const _KullaniciSecimi({
    required this.kullanicilar,
    required this.secili,
    required this.onSecildi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_KullaniciModel?>(
          value: secili,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          hint: const Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              Text(
                'Tüm Personel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          selectedItemBuilder: (context) {
            return [
              // "Tüm Personel" seçeneği için builder
              const Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tüm Personel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RaporlarScreen.black,
                    ),
                  ),
                ],
              ),
              ...kullanicilar.map(
                (k) => Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      k.adSoyad,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RaporlarScreen.black,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          items: [
            const DropdownMenuItem<_KullaniciModel?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Tüm Personel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...kullanicilar.map(
              (k) => DropdownMenuItem<_KullaniciModel?>(
                value: k,
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      k.adSoyad,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onSecildi,
        ),
      ),
    );
  }
}

// ── KPI Kart ──────────────────────────────────────────────────────────────────

class _KpiKart extends StatelessWidget {
  final String baslik;
  final String altBaslik;
  final int gerceklesen;
  final int hedef;
  final String birim;
  final IconData ikon;

  const _KpiKart({
    required this.baslik,
    required this.altBaslik,
    required this.gerceklesen,
    required this.hedef,
    required this.birim,
    required this.ikon,
  });

  Color get _renk {
    final oran = gerceklesen / hedef;
    if (oran >= 0.8) return const Color(0xFF2E7D32);
    if (oran >= 0.5) return const Color(0xFFD88900);
    return const Color(0xFFD32F2F);
  }

  String get _durum {
    final oran = gerceklesen / hedef;
    if (oran >= 0.8) return 'Hedefte';
    if (oran >= 0.5) return 'Takipte';
    return 'Kritik';
  }

  @override
  Widget build(BuildContext context) {
    final oran = math.min(gerceklesen / hedef, 1.0);
    final renk = _renk;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 20, color: renk),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _durum,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: renk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            altBaslik,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$gerceklesen',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: renk,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/$hedef $birim',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: oran,
              backgroundColor: renk.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(renk),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '%${(oran * 100).toStringAsFixed(0)} tamamlandı',
            style: TextStyle(
              fontSize: 11,
              color: renk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

// ── Tarih Filtresi ────────────────────────────────────────────────────────────

class _TarihFiltre extends StatelessWidget {
  final DateTime baslangic;
  final DateTime bitis;
  final VoidCallback onBaslangicSec;
  final VoidCallback onBitisSec;
  final String Function(DateTime) formatTarih;

  const _TarihFiltre({
    required this.baslangic,
    required this.bitis,
    required this.onBaslangicSec,
    required this.onBitisSec,
    required this.formatTarih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range_outlined,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onBaslangicSec,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Başlangıç',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatTarih(baslangic),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: RaporlarScreen.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF9E9E9E)),
          Expanded(
            child: GestureDetector(
              onTap: onBitisSec,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Bitiş',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatTarih(bitis),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: RaporlarScreen.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Özet Kartlar ──────────────────────────────────────────────────────────────

class _OzetKartlar extends StatelessWidget {
  final int toplam, tamamlanan, devamEden, teklifVerilen, planli;
  const _OzetKartlar({
    required this.toplam,
    required this.tamamlanan,
    required this.devamEden,
    required this.teklifVerilen,
    required this.planli,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaporlarScreen.yellow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_note_outlined,
                size: 36,
                color: RaporlarScreen.black,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toplam Aktivite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF555555),
                    ),
                  ),
                  Text(
                    toplam.toString(),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: RaporlarScreen.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OzetKart(
                label: 'Tamamlandı',
                deger: tamamlanan,
                renk: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OzetKart(
                label: 'Devam Ediyor',
                deger: devamEden,
                renk: const Color(0xFFD88900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OzetKart(
                label: 'Teklif Verildi',
                deger: teklifVerilen,
                renk: const Color(0xFF6A4CFF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OzetKart(
                label: 'Planlı',
                deger: planli,
                renk: const Color(0xFF0B5CFF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OzetKart extends StatelessWidget {
  final String label;
  final int deger;
  final Color renk;
  const _OzetKart({
    required this.label,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: renk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deger.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar Grafik ────────────────────────────────────────────────────────────────

class _TipBarGrafik extends StatelessWidget {
  final Map<String, int> tipDagilim;
  const _TipBarGrafik({required this.tipDagilim});

  String _tipLabel(String tip) {
    switch (tip) {
      case 'gorusme':
        return 'Görüşme';
      case 'telefon':
        return 'Telefon';
      case 'email':
        return 'E-posta';
      case 'toplanti':
        return 'Toplantı';
      case 'ziyaret':
        return 'Ziyaret';
      default:
        return 'Diğer';
    }
  }

  Color _tipRenk(String tip) {
    switch (tip) {
      case 'gorusme':
        return const Color(0xFF0B5CFF);
      case 'telefon':
        return const Color(0xFF2E7D32);
      case 'email':
        return const Color(0xFF6A4CFF);
      case 'toplanti':
        return const Color(0xFFD88900);
      case 'ziyaret':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sirali = tipDagilim.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxDeger = sirali.isEmpty ? 1 : sirali.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxDeger * 1.3,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final tip = sirali[groupIndex].key;
                  return BarTooltipItem(
                    '${_tipLabel(tip)}\n${rod.toY.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= sirali.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _tipLabel(sirali[idx].key),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  reservedSize: 36,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value == value.roundToDouble()) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: const Color(0xFFF0F0F0), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: sirali
                .asMap()
                .entries
                .map(
                  (e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        color: _tipRenk(e.value.key),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Durum Listesi ─────────────────────────────────────────────────────────────

class _DurumListesi extends StatelessWidget {
  final Map<String, int> durumDagilim;
  final int toplam;
  const _DurumListesi({required this.durumDagilim, required this.toplam});

  String _durumLabel(String durum) {
    switch (durum) {
      case 'planli':
        return 'Planlı';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'teklif_verildi':
        return 'Teklif Verildi';
      case 'iptal':
        return 'İptal';
      default:
        return durum;
    }
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'planli':
        return const Color(0xFF0B5CFF);
      case 'devam_ediyor':
        return const Color(0xFFD88900);
      case 'tamamlandi':
        return const Color(0xFF2E7D32);
      case 'teklif_verildi':
        return const Color(0xFF6A4CFF);
      case 'iptal':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sirali = durumDagilim.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        children: sirali.map((e) {
          final oran = toplam > 0 ? e.value / toplam : 0.0;
          final renk = _durumRenk(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: renk,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _durumLabel(e.key),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value}  (%${(oran * 100).toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: renk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: oran,
                    backgroundColor: renk.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(renk),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
