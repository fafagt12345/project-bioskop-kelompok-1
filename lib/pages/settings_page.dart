import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../theme/bubble_container.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MyApp.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppTheme.buildGradientAppBar(context, 'Pengaturan'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          BubbleContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profil'),
                  subtitle: const Text('Lihat dan ubah informasi akun'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur profil belum tersedia')),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Tema gelap'),
                  value: controller.isDark,
                  onChanged: (value) => controller.setDark(value),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang aplikasi'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'BioskopKu',
                    applicationVersion: '1.0.0',
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
