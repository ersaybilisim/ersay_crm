import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'storage_service.dart';

class BordrolarScreen extends StatefulWidget {
  const BordrolarScreen({super.key});

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  @override
  State<BordrolarScreen> createState() => _BordrolarScreenState();
}

class _BordrolarScreenState extends State<BordrolarScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> bordrolar = [];

  final String apiUrl = 'https://crmapi.ersayerp.com.tr/api/Bordrolar/personel';

  @override
  void initState() {
    super.initState();
    _loadBordrolar();
  }

  Future<void> _loadBordrolar() async {
    setState(() => isLoading = true);

    try {
      final token = await StorageService.getToken();

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          bordrolar = data.map((e) => Map<String, dynamic>.from(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showMessage('Bordrolar alınamadı. Kod: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('Hata: $e');
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      _showMessage('PDF açılamadı.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BordrolarScreen.bg,
      appBar: AppBar(
        backgroundColor: BordrolarScreen.bg,
        elevation: 0,
        foregroundColor: BordrolarScreen.black,
        title: const Text(
          'Bordrolarım',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: BordrolarScreen.yellow),
            )
          : bordrolar.isEmpty
          ? const Center(
              child: Text(
                'Bordro dosyası bulunamadı.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBordrolar,
              color: BordrolarScreen.yellow,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bordrolar.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = bordrolar[index];

                  final dosyaAdi = item['dosyaAdi']?.toString() ?? '-';
                  final url = item['url']?.toString() ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E1E1)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                        size: 34,
                      ),
                      title: Text(
                        dosyaAdi,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text('PDF bordro dosyası'),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: url.isEmpty ? null : () => _openPdf(url),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
