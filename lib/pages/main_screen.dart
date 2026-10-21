import 'package:flutter/material.dart';
import 'cariler_screen.dart';
import 'aktiviteler_screen.dart';
import 'raporlar_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../app_header.dart';
import 'profil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _seciliIndex = 0;

  final List<Widget> _sayfalar = const [
    CarilerScreen(),
    AktivitelerScreen(),
    RaporlarScreen(),
    ProfilScreen(),
  ];

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
              backgroundColor: const Color(0xFFFFC400),
              foregroundColor: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: IndexedStack(index: _seciliIndex, children: _sayfalar),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 82 + bottomPadding,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E1E1)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.business_outlined,
              title: 'Cariler',
              selected: _seciliIndex == 0,
              onTap: () => setState(() => _seciliIndex = 0),
            ),
            _NavItem(
              icon: Icons.event_note_outlined,
              title: 'Aktiviteler',
              selected: _seciliIndex == 1,
              onTap: () => setState(() => _seciliIndex = 1),
            ),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              title: 'Raporlar',
              selected: _seciliIndex == 2,
              onTap: () => setState(() => _seciliIndex = 2),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              title: 'Profilim',
              selected: _seciliIndex == 3,
              onTap: () => setState(() => _seciliIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  static const yellow = Color(0xFFFFC400);
  static const black = Color(0xFF111111);

  const _NavItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? yellow : black, size: 26),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: selected ? yellow : const Color(0xFF4B5563),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
