import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/masraf_service.dart';

class MasrafEkleScreen extends StatefulWidget {
  const MasrafEkleScreen({super.key});

  @override
  State<MasrafEkleScreen> createState() => _MasrafEkleScreenState();
}

class _MasrafEkleScreenState extends State<MasrafEkleScreen> {
  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  final _formKey = GlobalKey<FormState>();

  final txtAciklama = TextEditingController();
  final txtTutar = TextEditingController();
  final txtFaturaNo = TextEditingController();
  final txtTedarikci = TextEditingController();

  DateTime secilenTarih = DateTime.now();

  String? secilenKategori;
  String? secilenOdemeYontemi;

  File? secilenResim;
  bool kaydediliyor = false;

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

  @override
  void dispose() {
    txtAciklama.dispose();
    txtTutar.dispose();
    txtFaturaNo.dispose();
    txtTedarikci.dispose();
    super.dispose();
  }

  String _apiTarih(DateTime tarih) {
    return "${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}T00:00:00.000Z";
  }

  String _formatTarih(DateTime tarih) {
    return "${tarih.day.toString().padLeft(2, '0')}."
        "${tarih.month.toString().padLeft(2, '0')}."
        "${tarih.year}";
  }

  Future<void> _tarihSec() async {
    final result = await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (result != null) {
      setState(() {
        secilenTarih = result;
      });
    }
  }

  Future<void> _resimSec() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        secilenResim = File(image.path);
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
      ),
    );
  }

  int _findMasrafId(Map<String, dynamic> data) {
    final value =
        data['id'] ??
        data['Id'] ??
        data['masrafId'] ??
        data['MasrafId'] ??
        data['ID'];

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      kaydediliyor = true;
    });

    try {
      final tutar =
          double.tryParse(txtTutar.text.trim().replaceAll(',', '.')) ?? 0;

      final body = {
        "Tarih": _apiTarih(secilenTarih),
        "Kategori": secilenKategori,
        "Aciklama": txtAciklama.text.trim(),
        "Tutar": tutar.toInt(),
        "OdemeYontemi": secilenOdemeYontemi,
        "FaturaNo": txtFaturaNo.text.trim(),
        "Tedarikci": txtTedarikci.text.trim(),
        "KullaniciId": 1,
        "KullaniciAdi": "Erhan sayin",
      };

      final result = await MasrafService.masrafEkle(body: body);

      final masrafId = _findMasrafId(result);

      if (secilenResim != null && masrafId > 0) {
        await MasrafService.belgeYukle(masrafId: masrafId, file: secilenResim!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masraf başarıyla kaydedildi.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) {
        setState(() {
          kaydediliyor = false;
        });
      }
    }
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
          'Yeni Masraf',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  onTap: _tarihSec,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE1E1E1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatTarih(secilenTarih),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: secilenKategori,
                  decoration: _inputDecoration(
                    'Kategori',
                    Icons.category_outlined,
                  ),
                  items: kategoriler
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      secilenKategori = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Kategori seçiniz';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: secilenOdemeYontemi,
                  decoration: _inputDecoration(
                    'Ödeme Yöntemi',
                    Icons.payments_outlined,
                  ),
                  items: odemeYontemleri
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      secilenOdemeYontemi = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Ödeme yöntemi seçiniz';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: txtTutar,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Tutar', Icons.currency_lira),
                  validator: (value) {
                    final tutar = double.tryParse(
                      value?.trim().replaceAll(',', '.') ?? '',
                    );

                    if (tutar == null || tutar <= 0) {
                      return 'Geçerli bir tutar giriniz';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: txtTedarikci,
                  decoration: _inputDecoration(
                    'Tedarikçi',
                    Icons.store_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: txtFaturaNo,
                  decoration: _inputDecoration(
                    'Fatura / Fiş No',
                    Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: txtAciklama,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Açıklama',
                    Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _resimSec,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE1E1E1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            secilenResim == null
                                ? 'Fiş / Fatura Resmi Ekle'
                                : 'Fiş resmi seçildi',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                if (secilenResim != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      secilenResim!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: kaydediliyor ? null : _kaydet,
                    icon: kaydediliyor
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      kaydediliyor ? 'Kaydediliyor...' : 'Masrafı Kaydet',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
