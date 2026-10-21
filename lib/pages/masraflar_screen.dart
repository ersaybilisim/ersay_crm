import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/masraf_service.dart';
import 'masraf_ekle_screen.dart';
import '../services/storage_service.dart';

class MasraflarScreen extends StatefulWidget {
  const MasraflarScreen({super.key});

  @override
  State<MasraflarScreen> createState() => _MasraflarScreenState();
}

class _MasraflarScreenState extends State<MasraflarScreen> {
  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  bool isLoading = true;
  String? errorMessage;
  List<dynamic> masraflar = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> kategoriler = [
    'Yemek',
    'Ulaşım',
    'Konaklama',
    'Yakıt',
    'Ofis Gideri',
    'Telefon / İnternet',
    'Kargo',
    'Müşteri Ziyareti',
    'Temsil Ağırlama',
    'Diğer',
  ];

  final List<String> odemeYontemleri = [
    'Nakit',
    'Kredi Kartı',
    'Banka Kartı',
    'Havale / EFT',
    'Şirket Kartı',
    'Diğer',
  ];

  final List<String> durumlar = [
    'Beklemede',
    'Onaylandı',
    'Reddedildi',
    'Ödendi',
  ];

  @override
  void initState() {
    super.initState();
    _loadMasraflar();
  }

  Future<void> _loadMasraflar() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await MasrafService.getMasraflar();

      if (!mounted) return;

      setState(() {
        masraflar = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<bool> _adminMi() async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final data = jsonDecode(payload);

      final rol =
          data['role'] ??
          data['rol'] ??
          data['Role'] ??
          data['Rol'] ??
          data['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

      return rol.toString().toLowerCase() == 'admin';
    } catch (_) {
      return false;
    }
  }

  String _apiTarih(DateTime tarih) {
    return "${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}T00:00:00.000Z";
  }

  String _formatTutar(dynamic value) {
    final number =
        double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;

    return '${number.toStringAsFixed(2)} ₺';
  }

  String _formatTarih(dynamic value) {
    if (value == null) return '-';

    try {
      final tarih = DateTime.parse(value.toString());

      return "${tarih.day.toString().padLeft(2, '0')}."
          "${tarih.month.toString().padLeft(2, '0')}."
          "${tarih.year}";
    } catch (_) {
      return value.toString();
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  dynamic _field(dynamic item, String key) {
    return item[key] ?? item[_capitalize(key)] ?? item[key.toUpperCase()];
  }

  String _value(dynamic item, String key) {
    final value = _field(item, key);

    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    return value.toString();
  }

  int _intField(dynamic item, String key) {
    final value = _field(item, key);
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _odendiMi(dynamic item) {
    final durum = _value(item, 'durum').toLowerCase();
    return durum == 'ödendi' ||
        durum == 'odendi' ||
        durum == 'ödenmiş' ||
        durum == 'odenmis' ||
        durum == 'paid' ||
        durum == 'Reddedildi' ||
        durum == 'reddedildi';
  }

  bool _reddedildiMi(String durum) {
    final d = durum.toLowerCase();
    return d == 'reddedildi' ||
        d == 'red edildi' ||
        d == 'rededildi' ||
        d == 'rejected';
  }

  InputDecoration _modalDecoration(
    String label,
    IconData icon, {
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: readOnly ? const Color(0xFFF1F1F1) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
      ),
    );
  }

  Future<void> _yeniMasrafAc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MasrafEkleScreen()),
    );

    if (result == true) {
      await _loadMasraflar();
    }
  }

  Future<File?> _resimSec() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (image == null) return null;

    return File(image.path);
  }

  void _resimBuyut(String url) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Görsel yüklenemedi.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> _silOnayAl() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Masraf Silinsin mi?'),
          content: const Text(
            'Bu işlem geri alınamaz. Masraf kaydı ve bağlı fiş bilgisi silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _editModalAc(dynamic item) async {
    final bool adminMi = await _adminMi();

    final int id = _intField(item, 'id');
    final bool odendi = _odendiMi(item);
    final bool sadeceGoruntule = odendi;

    final txtAciklama = TextEditingController(
      text: _value(item, 'aciklama') == '-' ? '' : _value(item, 'aciklama'),
    );

    final txtTutar = TextEditingController(
      text: (_field(item, 'tutar') ?? '').toString(),
    );

    final txtFaturaNo = TextEditingController(
      text: _value(item, 'faturaNo') == '-' ? '' : _value(item, 'faturaNo'),
    );

    final txtTedarikci = TextEditingController(
      text: _value(item, 'tedarikci') == '-' ? '' : _value(item, 'tedarikci'),
    );

    final txtRedAciklama = TextEditingController(
      text: _value(item, 'redAciklama') == '-'
          ? ''
          : _value(item, 'redAciklama'),
    );

    String? kategori = _value(item, 'kategori') == '-'
        ? null
        : _value(item, 'kategori');

    String? odemeYontemi = _value(item, 'odemeYontemi') == '-'
        ? null
        : _value(item, 'odemeYontemi');

    String durum = _value(item, 'durum') == '-'
        ? 'Beklemede'
        : _value(item, 'durum');

    DateTime tarih =
        DateTime.tryParse((_field(item, 'tarih') ?? '').toString()) ??
        DateTime.now();

    String? belgeUrl = MasrafService.belgeUrlFromItem(item);

    File? yeniBelge;
    bool guncelleniyor = false;
    bool belgeYukleniyor = false;
    bool siliniyor = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> tarihSec() async {
              if (sadeceGoruntule) return;

              final result = await showDatePicker(
                context: context,
                initialDate: tarih,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );

              if (result != null) {
                setModalState(() {
                  tarih = result;
                });
              }
            }

            Future<void> belgeSecVeYukle() async {
              if (sadeceGoruntule) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ödenmiş veya Rededilmiş masraflarda fiş değiştirilemez.',
                    ),
                  ),
                );
                return;
              }

              if (id <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Belge yüklemek için masraf ID bulunamadı.'),
                  ),
                );
                return;
              }

              final file = await _resimSec();

              if (file == null) return;

              setModalState(() {
                yeniBelge = file;
                belgeYukleniyor = true;
              });

              try {
                await MasrafService.belgeYukle(masrafId: id, file: file);

                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Fiş görseli yüklendi.')),
                );

                await _loadMasraflar();
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Fiş yükleme hatası: $e')),
                );
              } finally {
                setModalState(() {
                  belgeYukleniyor = false;
                });
              }
            }

            Future<void> guncelle() async {
              if (sadeceGoruntule) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ödenmiş veya Rededilmiş masraflarda değişiklik yapılamaz.',
                    ),
                  ),
                );
                return;
              }

              final tutar =
                  double.tryParse(txtTutar.text.trim().replaceAll(',', '.')) ??
                  0;

              if (id <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Masraf ID bulunamadı.')),
                );
                return;
              }

              if (kategori == null || odemeYontemi == null || tutar <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kategori, ödeme yöntemi ve tutar zorunludur.',
                    ),
                  ),
                );
                return;
              }

              if (_reddedildiMi(durum) && txtRedAciklama.text.trim().isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Reddedilen masraflarda Red Açıklaması zorunludur.',
                    ),
                  ),
                );
                return;
              }

              setModalState(() {
                guncelleniyor = true;
              });

              try {
                final body = {
                  "Tarih": _apiTarih(tarih),
                  "Kategori": kategori,
                  "Aciklama": txtAciklama.text.trim(),
                  "Tutar": tutar.toInt(),
                  "OdemeYontemi": odemeYontemi,
                  "FaturaNo": txtFaturaNo.text.trim(),
                  "Tedarikci": txtTedarikci.text.trim(),
                  "Durum": durum,
                  "RedAciklama": _reddedildiMi(durum)
                      ? txtRedAciklama.text.trim()
                      : "",
                };

                await MasrafService.masrafGuncelle(id: id, body: body);

                if (!mounted) return;

                Navigator.of(modalContext).pop();

                await Future.delayed(const Duration(milliseconds: 250));

                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Masraf güncellendi.')),
                );

                await _loadMasraflar();
              } catch (e) {
                if (!mounted) return;

                setModalState(() {
                  guncelleniyor = false;
                });

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            }

            Future<void> sil() async {
              if (sadeceGoruntule) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Ödenmiş masraflar silinemez.')),
                );
                return;
              }

              if (id <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Masraf ID bulunamadı.')),
                );
                return;
              }

              final onay = await _silOnayAl();

              if (!onay) return;

              setModalState(() {
                siliniyor = true;
              });

              try {
                await MasrafService.masrafSil(id: id);

                if (!mounted) return;

                Navigator.of(modalContext).pop();

                await Future.delayed(const Duration(milliseconds: 250));

                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Masraf silindi.')),
                );

                await _loadMasraflar();
              } catch (e) {
                if (!mounted) return;

                setModalState(() {
                  siliniyor = false;
                });

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.90,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: const BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        IconButton(
                          onPressed:
                              guncelleniyor || belgeYukleniyor || siliniyor
                              ? null
                              : () {
                                  Navigator.of(modalContext).pop();
                                },
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            sadeceGoruntule
                                ? 'Masraf Görüntüle'
                                : 'Masraf Düzenle',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              sadeceGoruntule ||
                                  guncelleniyor ||
                                  belgeYukleniyor ||
                                  siliniyor
                              ? null
                              : sil,
                          icon: siliniyor
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                        ),
                      ],
                    ),
                    if (sadeceGoruntule) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.35),
                          ),
                        ),
                        child: const Text(
                          'Bu masraf ödenmiş durumdadır. Bilgiler görüntülenebilir ancak değiştirilemez.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: tarihSec,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: sadeceGoruntule
                                      ? const Color(0xFFF1F1F1)
                                      : Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE1E1E1),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _formatTarih(tarih.toIso8601String()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      sadeceGoruntule
                                          ? Icons.lock_outline
                                          : Icons.arrow_drop_down,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: kategoriler.contains(kategori)
                                  ? kategori
                                  : null,
                              decoration: _modalDecoration(
                                'Kategori',
                                Icons.category_outlined,
                                readOnly: sadeceGoruntule,
                              ),
                              items: kategoriler
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: sadeceGoruntule
                                  ? null
                                  : (value) {
                                      setModalState(() {
                                        kategori = value;
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: odemeYontemleri.contains(odemeYontemi)
                                  ? odemeYontemi
                                  : null,
                              decoration: _modalDecoration(
                                'Ödeme Yöntemi',
                                Icons.payments_outlined,
                                readOnly: sadeceGoruntule,
                              ),
                              items: odemeYontemleri
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: sadeceGoruntule
                                  ? null
                                  : (value) {
                                      setModalState(() {
                                        odemeYontemi = value;
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: txtTutar,
                              readOnly: sadeceGoruntule,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _modalDecoration(
                                'Tutar',
                                Icons.currency_lira,
                                readOnly: sadeceGoruntule,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: txtTedarikci,
                              readOnly: sadeceGoruntule,
                              decoration: _modalDecoration(
                                'Tedarikçi',
                                Icons.store_outlined,
                                readOnly: sadeceGoruntule,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: txtFaturaNo,
                              readOnly: sadeceGoruntule,
                              decoration: _modalDecoration(
                                'Fatura / Fiş No',
                                Icons.receipt_long_outlined,
                                readOnly: sadeceGoruntule,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: txtAciklama,
                              readOnly: sadeceGoruntule,
                              maxLines: 3,
                              decoration: _modalDecoration(
                                'Açıklama',
                                Icons.notes_outlined,
                                readOnly: sadeceGoruntule,
                              ),
                            ),
                            const SizedBox(height: 12),
                            adminMi && !sadeceGoruntule
                                ? DropdownButtonFormField<String>(
                                    value: durumlar.contains(durum)
                                        ? durum
                                        : 'Beklemede',
                                    decoration: _modalDecoration(
                                      'Durum',
                                      Icons.info_outline,
                                    ),
                                    items: durumlar
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        durum = value ?? durum;

                                        if (!_reddedildiMi(durum)) {
                                          txtRedAciklama.clear();
                                        }
                                      });
                                    },
                                  )
                                : InputDecorator(
                                    decoration: _modalDecoration(
                                      'Durum',
                                      sadeceGoruntule
                                          ? Icons.lock_outline
                                          : Icons.info_outline,
                                      readOnly: true,
                                    ),
                                    child: Text(
                                      durum,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                            if (_reddedildiMi(durum)) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: txtRedAciklama,
                                readOnly: sadeceGoruntule || !adminMi,
                                maxLines: 4,
                                decoration: _modalDecoration(
                                  'Red Açıklaması',
                                  Icons.cancel_outlined,
                                  readOnly: sadeceGoruntule || !adminMi,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE1E1E1),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.image_outlined),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fiş / Fatura Görseli',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (yeniBelge != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        yeniBelge!,
                                        width: double.infinity,
                                        height: 190,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else if (belgeUrl != null)
                                    InkWell(
                                      onTap: () => _resimBuyut(belgeUrl!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          belgeUrl!,
                                          width: double.infinity,
                                          height: 190,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return Container(
                                              height: 120,
                                              alignment: Alignment.center,
                                              color: const Color(0xFFF2F2F2),
                                              child: const Text(
                                                'Görsel yüklenemedi.',
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 90,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F2F2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Bu masrafa ait fiş görseli yok.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          sadeceGoruntule || belgeYukleniyor
                                          ? null
                                          : belgeSecVeYukle,
                                      icon: belgeYukleniyor
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              sadeceGoruntule
                                                  ? Icons.lock_outline
                                                  : Icons.camera_alt_outlined,
                                            ),
                                      label: Text(
                                        sadeceGoruntule
                                            ? 'Ödenmiş masrafta fiş değiştirilemez'
                                            : belgeYukleniyor
                                            ? 'Fiş Yükleniyor...'
                                            : 'Yeni Fiş Görseli Çek / Yükle',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!sadeceGoruntule)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: guncelleniyor ? null : guncelle,
                          icon: guncelleniyor
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            guncelleniyor
                                ? 'Güncelleniyor...'
                                : 'Değişiklikleri Kaydet',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: black,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(modalContext).pop();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Kapat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: yellow,
        foregroundColor: black,
        elevation: 0,
        title: const Text(
          'Masraflarım',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _loadMasraflar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: yellow,
        foregroundColor: black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Masraf',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: _yeniMasrafAc,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: yellow));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (masraflar.isEmpty) {
      return const Center(
        child: Text(
          'Henüz masraf kaydınız yok.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: black,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMasraflar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: masraflar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = masraflar[index];
          final durum = _value(item, 'durum');
          final odendi = _odendiMi(item);
          final belgeUrl = MasrafService.belgeUrlFromItem(item);
          final redAciklama = _value(item, 'redAciklama');

          return InkWell(
            onTap: () => _editModalAc(item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: odendi
                      ? Colors.green.withOpacity(0.35)
                      : _reddedildiMi(durum)
                      ? Colors.red.withOpacity(0.35)
                      : const Color(0xFFE1E1E1),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _reddedildiMi(durum)
                          ? Colors.red.withOpacity(0.14)
                          : yellow.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      belgeUrl == null
                          ? Icons.receipt_long_rounded
                          : Icons.image_rounded,
                      color: black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _value(item, 'kategori'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _value(item, 'aciklama'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Color(0xFF999999),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTarih(_field(item, 'tarih')),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              odendi
                                  ? Icons.check_circle_rounded
                                  : _reddedildiMi(durum)
                                  ? Icons.cancel_rounded
                                  : Icons.hourglass_bottom_rounded,
                              size: 14,
                              color: odendi
                                  ? Colors.green
                                  : _reddedildiMi(durum)
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              durum.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: odendi
                                    ? Colors.green
                                    : _reddedildiMi(durum)
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                            ),
                            if (belgeUrl != null) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.attach_file,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ],
                        ),
                        if (_reddedildiMi(durum) && redAciklama != '-') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Red Nedeni: $redAciklama',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatTutar(_field(item, 'tutar')),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
