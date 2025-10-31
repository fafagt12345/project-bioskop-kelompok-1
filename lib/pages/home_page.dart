import 'package:flutter/material.dart';
import 'film_list_page.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Bioskop • Home'), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HomeTile(
              icon: Icons.movie_outlined,
              title: 'Daftar Film',
              subtitle: 'Lihat film dari database',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FilmListPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HomeTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.7)),
          color: primary.withOpacity(0.03),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
