import 'package:flutter/material.dart';
import '../services/cari_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../app_header.dart';

class CarilerScreen extends StatefulWidget {
  const CarilerScreen({super.key});

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  @override
  State<CarilerScreen> createState() => _CarilerScreenState();
}

class _CarilerScreenState extends State<CarilerScreen> {
  List<CariModel> cariler = [];
  bool isLoading = true;
  String? hata;
  final TextEditingController aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCariler();
  }

  Future<void> _loadCariler({String? arama}) async {
    setState(() {
      isLoading = true;
      hata = null;
    });
    final result = await CariService.getCariler(arama: arama, aktif: true);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        cariler = result.items;
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

  void _cariEkleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CariEkleModal(onKayitTamamlandi: () => _loadCariler()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarilerScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadCariler(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(onEkle: _cariEkleModal),
                      const SizedBox(height: 18),
                      _SearchRowActive(
                        controller: aramaController,
                        onSearch: (v) => _loadCariler(arama: v),
                      ),
                      const SizedBox(height: 18),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: CarilerScreen.yellow,
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
                      else if (cariler.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('Cari bulunamadı'),
                          ),
                        )
                      else
                        ...cariler.map((c) => _CustomerCard(cari: c)),
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
            'Cariler',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: CarilerScreen.black,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onEkle,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Cari Ekle'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CarilerScreen.black,
            side: const BorderSide(color: CarilerScreen.yellow, width: 1.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search Row ────────────────────────────────────────────────────────────────

class _SearchRowActive extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  const _SearchRowActive({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSearch,
      decoration: InputDecoration(
        hintText: 'Cari ara...',
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => onSearch(controller.text),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
        ),
      ),
    );
  }
}

// ── Customer Card ─────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final CariModel cari;
  const _CustomerCard({required this.cari});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF0B5CFF),
      const Color(0xFF009879),
      const Color(0xFF6A4CFF),
      const Color(0xFFD88900),
      const Color(0xFFC2410C),
      const Color(0xFF0891B2),
    ];
    final avatarColor = colors[cari.id % colors.length];
    final statusColor = cari.aktif
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD88900);

    return GestureDetector(
      onTap: () => _showCariDetay(context, cari, avatarColor, statusColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E1E1)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColor.withOpacity(0.16),
              child: Text(
                cari.shortName,
                style: TextStyle(
                  color: avatarColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cari.unvan,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (cari.il != null) cari.il!,
                      if (cari.ilce != null) cari.ilce!,
                    ].join(' / '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  if (cari.telefon != null || cari.gsm != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cari.telefon ?? cari.gsm ?? '',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cari.aktif ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cari.cariTipi == 'musteri'
                      ? 'Müşteri'
                      : cari.cariTipi == 'tedarikci'
                      ? 'Tedarikçi'
                      : 'Her İkisi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

// ── Cari Detay Modal ──────────────────────────────────────────────────────────

void _showCariDetay(
  BuildContext context,
  CariModel cari,
  Color avatarColor,
  Color statusColor,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CariDetayModal(
      cari: cari,
      avatarColor: avatarColor,
      statusColor: statusColor,
    ),
  );
}

class _CariDetayModal extends StatefulWidget {
  final CariModel cari;
  final Color avatarColor;
  final Color statusColor;
  const _CariDetayModal({
    required this.cari,
    required this.avatarColor,
    required this.statusColor,
  });

  @override
  State<_CariDetayModal> createState() => _CariDetayModalState();
}

class _CariDetayModalState extends State<_CariDetayModal> {
  List<CariTemsilciModel> temsilciler = [];
  bool temsilciLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemsilciler();
  }

  Future<void> _loadTemsilciler() async {
    final result = await CariService.getTemsilciler(widget.cari.id);
    if (!mounted) return;
    setState(() {
      temsilciler = result;
      temsilciLoading = false;
    });
  }

  void _temsilciEkleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemsilciEkleModal(
        cariId: widget.cari.id,
        onKayitTamamlandi: _loadTemsilciler,
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
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: widget.avatarColor.withOpacity(0.16),
                  child: Text(
                    widget.cari.shortName,
                    style: TextStyle(
                      color: widget.avatarColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cari.unvan,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cari.cariKod,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.cari.aktif ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: widget.statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            const Text(
              'Cari Bilgileri',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 14),
            if (widget.cari.yetkiliKisi != null)
              _DetayRow(
                icon: Icons.person_outline_rounded,
                label: 'Yetkili',
                value: widget.cari.yetkiliKisi!,
              ),
            if (widget.cari.telefon != null)
              _DetayRow(
                icon: Icons.phone_outlined,
                label: 'Telefon',
                value: widget.cari.telefon!,
              ),
            if (widget.cari.gsm != null)
              _DetayRow(
                icon: Icons.smartphone_outlined,
                label: 'GSM',
                value: widget.cari.gsm!,
              ),
            if (widget.cari.email != null)
              _DetayRow(
                icon: Icons.mail_outline_rounded,
                label: 'E-posta',
                value: widget.cari.email!,
              ),
            if (widget.cari.il != null || widget.cari.ilce != null)
              _DetayRow(
                icon: Icons.location_on_outlined,
                label: 'Konum',
                value: [
                  if (widget.cari.il != null) widget.cari.il!,
                  if (widget.cari.ilce != null) widget.cari.ilce!,
                ].join(' / '),
              ),
            if (widget.cari.adres != null)
              _DetayRow(
                icon: Icons.home_outlined,
                label: 'Adres',
                value: widget.cari.adres!,
              ),
            _DetayRow(
              icon: Icons.category_outlined,
              label: 'Cari Tipi',
              value: widget.cari.cariTipi == 'musteri'
                  ? 'Müşteri'
                  : widget.cari.cariTipi == 'tedarikci'
                  ? 'Tedarikçi'
                  : 'Her İkisi',
            ),
            _DetayRow(
              icon: Icons.phone_callback_outlined,
              label: 'Arama Durumu',
              value: _aramaDurumuText(widget.cari.aramaDurumu),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cari Temsilcileri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                if (!temsilciLoading)
                  GestureDetector(
                    onTap: _temsilciEkleModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CarilerScreen.yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: CarilerScreen.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Temsilci Ekle',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CarilerScreen.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (temsilciLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: CarilerScreen.yellow,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (temsilciler.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Kayıtlı temsilci bulunamadı',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...temsilciler.map((t) => _TemsilciKart(temsilci: t)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC400),
                  foregroundColor: const Color(0xFF111111),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kapat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _aramaDurumuText(String durum) {
    switch (durum) {
      case 'aranmadi':
        return 'Aranmadı';
      case 'arama_yapildi':
        return 'Arama Yapıldı';
      case 'tekrar_aranacak':
        return 'Tekrar Aranacak';
      case 'tamamlandi':
        return 'Tamamlandı';
      default:
        return durum;
    }
  }
}

// ── Cari Ekle Modal ───────────────────────────────────────────────────────────

class _CariEkleModal extends StatefulWidget {
  final VoidCallback onKayitTamamlandi;
  const _CariEkleModal({required this.onKayitTamamlandi});

  @override
  State<_CariEkleModal> createState() => _CariEkleModalState();
}

class _CariEkleModalState extends State<_CariEkleModal> {
  final _unvanController = TextEditingController();
  final _yetkiliController = TextEditingController();
  final _telefonController = TextEditingController();
  final _gsmController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresController = TextEditingController();
  final _ilController = TextEditingController();
  final _ilceController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _vergiNoController = TextEditingController();

  bool _kayitYapiliyor = false;
  int? _kaydedilenCariId;

  @override
  void dispose() {
    _unvanController.dispose();
    _yetkiliController.dispose();
    _telefonController.dispose();
    _gsmController.dispose();
    _emailController.dispose();
    _adresController.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    _vergiDairesiController.dispose();
    _vergiNoController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_unvanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ünvan zorunludur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _kayitYapiliyor = true);
    final result = await CariService.cariKaydet(
      unvan: _unvanController.text.trim(),
      yetkiliKisi: _yetkiliController.text.trim().isEmpty
          ? null
          : _yetkiliController.text.trim(),
      telefon: _telefonController.text.trim().isEmpty
          ? null
          : _telefonController.text.trim(),
      gsm: _gsmController.text.trim().isEmpty
          ? null
          : _gsmController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      adres: _adresController.text.trim().isEmpty
          ? null
          : _adresController.text.trim(),
      il: _ilController.text.trim().isEmpty ? null : _ilController.text.trim(),
      ilce: _ilceController.text.trim().isEmpty
          ? null
          : _ilceController.text.trim(),
      vergiDairesi: _vergiDairesiController.text.trim().isEmpty
          ? null
          : _vergiDairesiController.text.trim(),
      vergiNo: _vergiNoController.text.trim().isEmpty
          ? null
          : _vergiNoController.text.trim(),
      cariTipi: 'musteri',
    );
    if (!mounted) return;
    setState(() => _kayitYapiliyor = false);
    if (result != null) {
      setState(() => _kaydedilenCariId = result['Id']);
      widget.onKayitTamamlandi();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cari başarıyla kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt sırasında hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _temsilciEkle() {
    if (_kaydedilenCariId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemsilciEkleModal(
        cariId: _kaydedilenCariId!,
        onKayitTamamlandi: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

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
              const Text(
                'Yeni Cari Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 20),
              _FormAlan(
                controller: _unvanController,
                label: 'Ünvan *',
                hint: 'Firma ünvanı',
              ),
              _FormAlan(
                controller: _yetkiliController,
                label: 'Yetkili Kişi',
                hint: 'Ad soyad',
              ),
              _FormAlan(
                controller: _telefonController,
                label: 'Telefon',
                hint: '0212 000 0000',
                keyboardType: TextInputType.phone,
              ),
              _FormAlan(
                controller: _gsmController,
                label: 'GSM',
                hint: '0532 000 0000',
                keyboardType: TextInputType.phone,
              ),
              _FormAlan(
                controller: _emailController,
                label: 'E-posta',
                hint: 'ornek@firma.com',
                keyboardType: TextInputType.emailAddress,
              ),
              _FormAlan(
                controller: _adresController,
                label: 'Adres',
                hint: 'Açık adres',
                maxLines: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: _FormAlan(
                      controller: _ilController,
                      label: 'İl',
                      hint: 'İstanbul',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormAlan(
                      controller: _ilceController,
                      label: 'İlçe',
                      hint: 'Kadıköy',
                    ),
                  ),
                ],
              ),
              _FormAlan(
                controller: _vergiDairesiController,
                label: 'Vergi Dairesi',
                hint: 'Vergi dairesi adı',
              ),
              _FormAlan(
                controller: _vergiNoController,
                label: 'Vergi No',
                hint: '1234567890',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              if (_kaydedilenCariId != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _temsilciEkle,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text(
                      'Cari Temsilcisi Ekle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CarilerScreen.black,
                      side: const BorderSide(
                        color: CarilerScreen.yellow,
                        width: 1.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CarilerScreen.black,
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
                          backgroundColor: CarilerScreen.yellow,
                          foregroundColor: CarilerScreen.black,
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
                                _kaydedilenCariId != null
                                    ? 'Güncelle'
                                    : 'Kaydet',
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

// ── Temsilci Ekle Modal ───────────────────────────────────────────────────────

class _TemsilciEkleModal extends StatefulWidget {
  final int cariId;
  final VoidCallback onKayitTamamlandi;
  const _TemsilciEkleModal({
    required this.cariId,
    required this.onKayitTamamlandi,
  });

  @override
  State<_TemsilciEkleModal> createState() => _TemsilciEkleModalState();
}

class _TemsilciEkleModalState extends State<_TemsilciEkleModal> {
  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _gsmController = TextEditingController();
  final _emailController = TextEditingController();
  final _pozisyonController = TextEditingController();
  bool _kayitYapiliyor = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _gsmController.dispose();
    _emailController.dispose();
    _pozisyonController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_adSoyadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad soyad zorunludur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _kayitYapiliyor = true);
    final ok = await CariService.temsilciKaydet(
      cariId: widget.cariId,
      adSoyad: _adSoyadController.text.trim(),
      telefon: _telefonController.text.trim().isEmpty
          ? null
          : _telefonController.text.trim(),
      gsm: _gsmController.text.trim().isEmpty
          ? null
          : _gsmController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      pozisyon: _pozisyonController.text.trim().isEmpty
          ? null
          : _pozisyonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _kayitYapiliyor = false);
    if (ok) {
      widget.onKayitTamamlandi();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temsilci başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt sırasında hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

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
              const Text(
                'Temsilci Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 20),
              _FormAlan(
                controller: _adSoyadController,
                label: 'Ad Soyad *',
                hint: 'Ad soyad',
              ),
              _FormAlan(
                controller: _pozisyonController,
                label: 'Pozisyon',
                hint: 'Satış Müdürü',
              ),
              _FormAlan(
                controller: _telefonController,
                label: 'Telefon',
                hint: '0212 000 0000',
                keyboardType: TextInputType.phone,
              ),
              _FormAlan(
                controller: _gsmController,
                label: 'GSM',
                hint: '0532 000 0000',
                keyboardType: TextInputType.phone,
              ),
              _FormAlan(
                controller: _emailController,
                label: 'E-posta',
                hint: 'ornek@firma.com',
                keyboardType: TextInputType.emailAddress,
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
                          foregroundColor: CarilerScreen.black,
                          side: const BorderSide(color: Color(0xFFDCDCDC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
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
                          backgroundColor: CarilerScreen.yellow,
                          foregroundColor: CarilerScreen.black,
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
                            : const Text(
                                'Kaydet',
                                style: TextStyle(
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
                  color: CarilerScreen.yellow,
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

class _TemsilciKart extends StatelessWidget {
  final CariTemsilciModel temsilci;
  const _TemsilciKart({required this.temsilci});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  temsilci.adSoyad,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              if (temsilci.pozisyon != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC400).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    temsilci.pozisyon!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF856200),
                    ),
                  ),
                ),
            ],
          ),
          if (temsilci.telefon != null || temsilci.gsm != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  temsilci.telefon ?? temsilci.gsm ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ],
          if (temsilci.email != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    temsilci.email!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
