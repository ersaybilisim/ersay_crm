import 'package:flutter/material.dart';
import '../services/aktivite_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../app_header.dart';

class AktivitelerScreen extends StatefulWidget {
  const AktivitelerScreen({super.key});

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  @override
  State<AktivitelerScreen> createState() => _AktivitelerScreenState();
}

class _AktivitelerScreenState extends State<AktivitelerScreen> {
  List<AktiviteModel> aktiviteler = [];
  bool isLoading = true;
  String? hata;
  String? seciliDurum;

  @override
  void initState() {
    super.initState();
    _loadAktiviteler();
  }

  Future<void> _loadAktiviteler() async {
    setState(() {
      isLoading = true;
      hata = null;
    });
    final result = await AktiviteService.getAktiviteler(durum: seciliDurum);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        aktiviteler = result.items;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        hata = result.errorMessage;
      });
      if (result.errorMessage == 'Oturum süresi doldu') {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _yeniAktiviteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AktiviteFormModal(onTamamlandi: _loadAktiviteler),
    );
  }

  Future<void> _silAktivite(int id) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Aktiviteyi Sil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Bu aktiviteyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (onay == true) {
      final ok = await AktiviteService.aktiviteSil(id);
      if (!mounted) return;
      if (ok) {
        _loadAktiviteler();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivite silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silme işlemi başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AktivitelerScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadAktiviteler(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(onEkle: _yeniAktiviteModal),
                      const SizedBox(height: 18),
                      _DurumFiltre(
                        secili: seciliDurum,
                        onSecildi: (v) {
                          setState(() => seciliDurum = v);
                          _loadAktiviteler();
                        },
                      ),
                      const SizedBox(height: 18),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: AktivitelerScreen.yellow,
                            ),
                          ),
                        )
                      else if (hata != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              hata!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (aktiviteler.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('Aktivite bulunamadı'),
                          ),
                        )
                      else
                        ...aktiviteler.map(
                          (a) => _AktiviteKart(
                            aktivite: a,
                            onSil: () => _silAktivite(a.id),
                            onDetay: () => _showAktiviteDetay(
                              context,
                              a.id,
                              _loadAktiviteler,
                            ),
                          ),
                        ),
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

// ── Title Row ─────────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  final VoidCallback onEkle;
  const _TitleRow({required this.onEkle});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Aktiviteler',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AktivitelerScreen.black,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onEkle,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Aktivite'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AktivitelerScreen.black,
            side: const BorderSide(color: AktivitelerScreen.yellow, width: 1.6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Durum Filtre ──────────────────────────────────────────────────────────────

class _DurumFiltre extends StatelessWidget {
  final String? secili;
  final Function(String?) onSecildi;
  const _DurumFiltre({required this.secili, required this.onSecildi});

  @override
  Widget build(BuildContext context) {
    final durumlar = [
      {'label': 'Tümü', 'value': null},
      {'label': 'Planlı', 'value': 'planli'},
      {'label': 'Devam Ediyor', 'value': 'devam_ediyor'},
      {'label': 'Tamamlandı', 'value': 'tamamlandi'},
      {'label': 'Teklif Verildi', 'value': 'teklif_verildi'},
      {'label': 'İptal', 'value': 'iptal'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: durumlar.map((d) {
          final isSelected = secili == d['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSecildi(d['value'] as String?),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AktivitelerScreen.yellow : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AktivitelerScreen.yellow
                        : const Color(0xFFDCDCDC),
                  ),
                ),
                child: Text(
                  d['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AktivitelerScreen.black
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Aktivite Kartı (Swipeable) ────────────────────────────────────────────────

class _AktiviteKart extends StatefulWidget {
  final AktiviteModel aktivite;
  final VoidCallback onSil;
  final VoidCallback onDetay;
  const _AktiviteKart({
    required this.aktivite,
    required this.onSil,
    required this.onDetay,
  });

  @override
  State<_AktiviteKart> createState() => _AktiviteKartState();
}

class _AktiviteKartState extends State<_AktiviteKart> {
  double _offset = 0;
  static const double _silButonGenislik = 80;

  @override
  Widget build(BuildContext context) {
    final durumRenk = _durumRenk(widget.aktivite.durum);
    final tipIkon = _tipIkon(widget.aktivite.aktiviteTipi);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onSil,
                child: Container(
                  width: _silButonGenislik,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _offset += d.delta.dx;
                if (_offset > 0) _offset = 0;
                if (_offset < -_silButonGenislik) _offset = -_silButonGenislik;
              });
            },
            onHorizontalDragEnd: (d) {
              setState(() {
                _offset = _offset < -_silButonGenislik / 2
                    ? -_silButonGenislik
                    : 0;
              });
            },
            onTap: () {
              if (_offset != 0) {
                setState(() => _offset = 0);
              } else {
                widget.onDetay();
              }
            },
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE1E1E1)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: durumRenk.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(tipIkon, color: durumRenk, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.aktivite.konu,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111111),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.aktivite.cariUnvan != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.aktivite.cariUnvan!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: durumRenk.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _durumText(widget.aktivite.durum),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: durumRenk,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTarih(widget.aktivite.baslangicTarihi),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.aktivite.sorumluAdSoyad ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFBBBBBB),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  IconData _tipIkon(String tip) {
    switch (tip) {
      case 'telefon':
        return Icons.phone_outlined;
      case 'email':
        return Icons.mail_outline_rounded;
      case 'toplanti':
        return Icons.groups_outlined;
      case 'ziyaret':
        return Icons.directions_walk_outlined;
      case 'gorusme':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.event_note_outlined;
    }
  }

  String _durumText(String durum) {
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

  String _formatTarih(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Aktivite Detay Modal ──────────────────────────────────────────────────────

void _showAktiviteDetay(
  BuildContext context,
  int id,
  VoidCallback onGuncellendi,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _AktiviteDetayModal(aktiviteId: id, onGuncellendi: onGuncellendi),
  );
}

class _AktiviteDetayModal extends StatefulWidget {
  final int aktiviteId;
  final VoidCallback onGuncellendi;
  const _AktiviteDetayModal({
    required this.aktiviteId,
    required this.onGuncellendi,
  });

  @override
  State<_AktiviteDetayModal> createState() => _AktiviteDetayModalState();
}

class _AktiviteDetayModalState extends State<_AktiviteDetayModal> {
  AktiviteDetayModel? detay;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetay();
  }

  Future<void> _loadDetay() async {
    final result = await AktiviteService.getAktiviteDetay(widget.aktiviteId);
    if (!mounted) return;
    setState(() {
      detay = result;
      isLoading = false;
    });
  }

  void _duzenle() {
    if (detay == null) return;
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AktiviteFormModal(
        mevcutDetay: detay,
        onTamamlandi: widget.onGuncellendi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: AktivitelerScreen.yellow,
                  ),
                ),
              )
            else if (detay == null)
              const Center(child: Text('Aktivite bulunamadı'))
            else ...[
              _DetayIcerik(detay: detay!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AktivitelerScreen.black,
                          side: const BorderSide(color: Color(0xFFDCDCDC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _duzenle,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Düzenle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AktivitelerScreen.yellow,
                          foregroundColor: AktivitelerScreen.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetayIcerik extends StatelessWidget {
  final AktiviteDetayModel detay;
  const _DetayIcerik({required this.detay});

  @override
  Widget build(BuildContext context) {
    final durumRenk = _durumRenk(detay.durum);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detay.konu,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: durumRenk.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _durumText(detay.durum),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: durumRenk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
        if (detay.cariUnvan != null)
          _DetayRow(
            icon: Icons.business_outlined,
            label: 'Cari',
            value: detay.cariUnvan!,
          ),
        _DetayRow(
          icon: Icons.event_note_outlined,
          label: 'Aktivite Tipi',
          value: _tipText(detay.aktiviteTipi),
        ),
        _DetayRow(
          icon: Icons.calendar_today_outlined,
          label: 'Başlangıç',
          value: _formatTarih(detay.baslangicTarihi),
        ),
        if (detay.bitisTarihi != null)
          _DetayRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bitiş',
            value: _formatTarih(detay.bitisTarihi!),
          ),
        if (detay.sorumluAdSoyad != null)
          _DetayRow(
            icon: Icons.person_outline_rounded,
            label: 'Sorumlu',
            value: detay.sorumluAdSoyad!,
          ),
        if (detay.olusturanAdSoyad != null)
          _DetayRow(
            icon: Icons.person_add_outlined,
            label: 'Oluşturan',
            value: detay.olusturanAdSoyad!,
          ),
        if (detay.aciklama != null && detay.aciklama!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Açıklama',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              detay.aciklama!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF444444),
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
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

  String _durumText(String durum) {
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

  String _tipText(String tip) {
    switch (tip) {
      case 'telefon':
        return 'Telefon';
      case 'email':
        return 'E-posta';
      case 'toplanti':
        return 'Toplantı';
      case 'ziyaret':
        return 'Ziyaret';
      case 'gorusme':
        return 'Görüşme';
      default:
        return 'Diğer';
    }
  }

  String _formatTarih(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Aktivite Form Modal ───────────────────────────────────────────────────────

class _AktiviteFormModal extends StatefulWidget {
  final AktiviteDetayModel? mevcutDetay;
  final VoidCallback onTamamlandi;
  const _AktiviteFormModal({this.mevcutDetay, required this.onTamamlandi});

  @override
  State<_AktiviteFormModal> createState() => _AktiviteFormModalState();
}

class _AktiviteFormModalState extends State<_AktiviteFormModal> {
  final _konuController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _cariAramaController = TextEditingController();

  String _aktiviteTipi = 'gorusme';
  String _durum = 'planli';
  DateTime _baslangicTarihi = DateTime.now();
  DateTime? _bitisTarihi;
  int? _seciliCariId;
  String? _seciliCariUnvan;
  bool _kayitYapiliyor = false;
  bool _cariAramaAcik = false;
  List<CariAramaModel> _cariSonuclari = [];
  bool _cariAraniyor = false;

  bool get _guncelleme => widget.mevcutDetay != null;

  @override
  void initState() {
    super.initState();
    if (_guncelleme) {
      final d = widget.mevcutDetay!;
      _konuController.text = d.konu;
      _aciklamaController.text = d.aciklama ?? '';
      _aktiviteTipi = d.aktiviteTipi;
      _durum = d.durum;
      _baslangicTarihi = d.baslangicTarihi;
      _bitisTarihi = d.bitisTarihi;
      _seciliCariId = d.cariId;
      _seciliCariUnvan = d.cariUnvan;
      if (d.cariUnvan != null) _cariAramaController.text = d.cariUnvan!;
    }
  }

  @override
  void dispose() {
    _konuController.dispose();
    _aciklamaController.dispose();
    _cariAramaController.dispose();
    super.dispose();
  }

  Future<void> _cariAra(String q) async {
    if (q.length < 2) {
      setState(() => _cariSonuclari = []);
      return;
    }
    setState(() => _cariAraniyor = true);
    final sonuc = await AktiviteService.cariAra(q);
    if (!mounted) return;
    setState(() {
      _cariSonuclari = sonuc;
      _cariAraniyor = false;
    });
  }

  Future<void> _tarihSec(bool baslangic) async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: baslangic
          ? _baslangicTarihi
          : (_bitisTarihi ?? _baslangicTarihi),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr'),
    );
    if (secilen != null) {
      setState(() {
        if (baslangic)
          _baslangicTarihi = secilen;
        else
          _bitisTarihi = secilen;
      });
    }
  }

  Future<void> _kaydet() async {
    if (_konuController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konu zorunludur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _kayitYapiliyor = true);

    bool ok;
    if (_guncelleme) {
      ok = await AktiviteService.aktiviteGuncelle(
        id: widget.mevcutDetay!.id,
        cariId: _seciliCariId,
        konu: _konuController.text.trim(),
        aciklama: _aciklamaController.text.trim().isEmpty
            ? null
            : _aciklamaController.text.trim(),
        aktiviteTipi: _aktiviteTipi,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
        durum: _durum,
      );
    } else {
      ok = await AktiviteService.aktiviteKaydet(
        cariId: _seciliCariId,
        konu: _konuController.text.trim(),
        aciklama: _aciklamaController.text.trim().isEmpty
            ? null
            : _aciklamaController.text.trim(),
        aktiviteTipi: _aktiviteTipi,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
        durum: _durum,
      );
    }

    if (!mounted) return;
    setState(() => _kayitYapiliyor = false);

    if (ok) {
      widget.onTamamlandi();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _guncelleme ? 'Aktivite güncellendi' : 'Aktivite kaydedildi',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    final String formatBas =
        '${_baslangicTarihi.day.toString().padLeft(2, '0')}.${_baslangicTarihi.month.toString().padLeft(2, '0')}.${_baslangicTarihi.year}';
    final String? formatBit = _bitisTarihi == null
        ? null
        : '${_bitisTarihi!.day.toString().padLeft(2, '0')}.${_bitisTarihi!.month.toString().padLeft(2, '0')}.${_bitisTarihi!.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _guncelleme ? 'Aktiviteyi Düzenle' : 'Yeni Aktivite',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 20),
              _FormAlan(
                controller: _konuController,
                label: 'Konu *',
                hint: 'Aktivite konusu',
              ),
              _EtiketliAlan(
                label: 'Cari',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _cariAramaAcik = !_cariAramaAcik),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCDCDC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _seciliCariUnvan ?? 'Cari seç (opsiyonel)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _seciliCariUnvan != null
                                      ? const Color(0xFF111111)
                                      : const Color(0xFF98A2B3),
                                ),
                              ),
                            ),
                            if (_seciliCariId != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _seciliCariId = null;
                                  _seciliCariUnvan = null;
                                  _cariAramaController.clear();
                                  _cariSonuclari = [];
                                }),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                              )
                            else
                              const Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_cariAramaAcik) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cariAramaController,
                        onChanged: _cariAra,
                        decoration: InputDecoration(
                          hintText: 'Cari adı ara...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _cariAraniyor
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCDCDC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AktivitelerScreen.yellow,
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                      if (_cariSonuclari.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCDCDC)),
                          ),
                          child: Column(
                            children: _cariSonuclari
                                .map(
                                  (c) => ListTile(
                                    title: Text(
                                      c.unvan,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.cariKod,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => setState(() {
                                      _seciliCariId = c.id;
                                      _seciliCariUnvan = c.unvan;
                                      _cariAramaAcik = false;
                                      _cariSonuclari = [];
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EtiketliAlan(
                label: 'Aktivite Tipi',
                child: _SecimButonlari(
                  secenekler: const [
                    {'label': 'Görüşme', 'value': 'gorusme'},
                    {'label': 'Telefon', 'value': 'telefon'},
                    {'label': 'E-posta', 'value': 'email'},
                    {'label': 'Yerinde Toplantı', 'value': 'toplanti'},
                    {'label': 'Online Toplantı', 'value': 'otoplanti'},
                    {'label': 'Ziyaret', 'value': 'ziyaret'},
                    {'label': 'Diğer', 'value': 'diger'},
                  ],
                  secili: _aktiviteTipi,
                  onSecildi: (v) => setState(() => _aktiviteTipi = v),
                ),
              ),
              const SizedBox(height: 14),
              _EtiketliAlan(
                label: 'Durum',
                child: _SecimButonlari(
                  secenekler: const [
                    {'label': 'Planlı', 'value': 'planli'},
                    {'label': 'Devam Ediyor', 'value': 'devam_ediyor'},
                    {'label': 'Tamamlandı', 'value': 'tamamlandi'},
                    {'label': 'Teklif Verildi', 'value': 'teklif_verildi'},
                    {'label': 'İptal', 'value': 'iptal'},
                  ],
                  secili: _durum,
                  onSecildi: (v) => setState(() => _durum = v),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _EtiketliAlan(
                      label: 'Başlangıç',
                      child: GestureDetector(
                        onTap: () => _tarihSec(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCDCDC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatBas,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EtiketliAlan(
                      label: 'Bitiş',
                      child: GestureDetector(
                        onTap: () => _tarihSec(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCDCDC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatBit ?? 'Seç',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: formatBit != null
                                      ? const Color(0xFF111111)
                                      : const Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormAlan(
                controller: _aciklamaController,
                label: 'Açıklama',
                hint: 'Detaylı açıklama...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AktivitelerScreen.black,
                          side: const BorderSide(color: Color(0xFFDCDCDC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _kayitYapiliyor ? null : _kaydet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AktivitelerScreen.yellow,
                          foregroundColor: AktivitelerScreen.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _kayitYapiliyor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _guncelleme ? 'Güncelle' : 'Kaydet',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────────────────────────

class _FormAlan extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _FormAlan({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AktivitelerScreen.yellow,
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtiketliAlan extends StatelessWidget {
  final String label;
  final Widget child;
  const _EtiketliAlan({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SecimButonlari extends StatelessWidget {
  final List<Map<String, String>> secenekler;
  final String secili;
  final Function(String) onSecildi;

  const _SecimButonlari({
    required this.secenekler,
    required this.secili,
    required this.onSecildi,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: secenekler.map((s) {
        final isSelected = s['value'] == secili;
        return GestureDetector(
          onTap: () => onSecildi(s['value']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AktivitelerScreen.yellow
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AktivitelerScreen.yellow
                    : const Color(0xFFDCDCDC),
              ),
            ),
            child: Text(
              s['label']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AktivitelerScreen.black
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DetayRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetayRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
