import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../services/storage_service.dart';
import 'masraflar_screen.dart';
import '../services/bordrolar_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFF7F7F7);

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String adSoyad = '-';
  String email = '-';
  String rol = '-';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final data = jsonDecode(payload) as Map<String, dynamic>;

      final tokenAdSoyad =
          data['AdSoyad'] ??
          data['adSoyad'] ??
          data['name'] ??
          data['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'];

      final tokenEmail =
          data['email'] ??
          data['Email'] ??
          data['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];

      final tokenRol =
          data['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          data['role'] ??
          data['Rol'];

      if (!mounted) return;
      setState(() {
        adSoyad = tokenAdSoyad?.toString().trim().isNotEmpty == true
            ? tokenAdSoyad.toString()
            : '-';
        email = tokenEmail?.toString().trim().isNotEmpty == true
            ? tokenEmail.toString()
            : '-';
        rol = tokenRol?.toString().trim().isNotEmpty == true
            ? tokenRol.toString()
            : '-';
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfilScreen.yellow,
              foregroundColor: ProfilScreen.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (onay == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String get _avatarText {
    final clean = adSoyad.trim();
    if (clean.isEmpty || clean == '-') return 'E';

    final parts = clean.split(' ').where((x) => x.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return clean.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilScreen.bg,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ProfilScreen.yellow),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profilim',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: ProfilScreen.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileHeroCard(
                      avatarText: _avatarText,
                      adSoyad: adSoyad,
                      email: email,
                      rol: rol,
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Kullanıcı Bilgileri',
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Ad Soyad',
                          value: adSoyad,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'E-posta',
                          value: email,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Rol',
                          value: rol,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Hesap İşlemleri',
                      children: [
                        _ActionRow(
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'Bordrolarım',
                          subtitle: 'Aylık bordro PDF dosyalarını görüntüle',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BordrolarScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.receipt_long_rounded,
                          title: 'Masraflarım',
                          subtitle:
                              'Masraf fişlerini görüntüle ve yeni masraf gir',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MasraflarScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          title: 'Çıkış Yap',
                          subtitle: 'Oturumu güvenli şekilde kapat',
                          danger: true,
                          onTap: _logout,
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

class _ProfileHeroCard extends StatelessWidget {
  final String avatarText;
  final String adSoyad;
  final String email;
  final String rol;

  const _ProfileHeroCard({
    required this.avatarText,
    required this.adSoyad,
    required this.email,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: ProfilScreen.yellow.withOpacity(0.22),
            child: Text(
              avatarText,
              style: const TextStyle(
                color: ProfilScreen.black,
                fontSize: 22,
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
                  adSoyad,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: ProfilScreen.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ProfilScreen.yellow.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rol,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856200),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: ProfilScreen.black,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
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
                fontWeight: FontWeight.w800,
                color: ProfilScreen.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFD32F2F) : ProfilScreen.black;
    final bgColor = danger ? const Color(0xFFFFEEEE) : const Color(0xFFF7F7F7);
    final borderColor = danger
        ? const Color(0xFFFFCCCC)
        : const Color(0xFFE8E8E8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
