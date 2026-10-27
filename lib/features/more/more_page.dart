import 'package:doku/core/constants.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/services/app_preferences.dart';
import 'package:doku/features/categories/categories_screen.dart';
import 'package:doku/features/import_export/import_screen.dart';
import 'package:doku/features/more/info_screens.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static Future<void> openUrl(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((Object _) => false);
    if (!ok && context.mounted) {
      context.showSnack('Tidak dapat membuka tautan.', error: true);
    }
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Pengaturan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SectionHeader('Tampilan'),
          const _Group(children: [_DarkModeSwitch()]),
          const SectionHeader('Kelola'),
          _Group(
            children: [
              _Item(
                icon: Icons.label_outline_rounded,
                title: 'Kategori',
                subtitle: 'Atur kategori pemasukan & pengeluaran',
                onTap: () => _push(context, const CategoriesScreen()),
              ),
              _Item(
                icon: Icons.upload_file_rounded,
                title: 'Impor Excel',
                subtitle: 'Tambahkan transaksi dari file .xlsx',
                onTap: () => _push(context, const ImportScreen()),
              ),
            ],
          ),
          const SectionHeader('Bantuan'),
          _Group(
            children: [
              _Item(
                icon: Icons.help_outline_rounded,
                title: 'FAQ',
                onTap: () => _push(context, const FaqScreen()),
              ),
              _Item(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Kritik & Saran',
                onTap: () => openUrl(context, AppConstants.feedbackFormUrl),
              ),
              _Item(
                icon: Icons.shield_outlined,
                title: 'Disclaimer',
                onTap: () => _push(context, const DisclaimerScreen()),
              ),
            ],
          ),
          const SectionHeader('Aplikasi'),
          _Group(
            children: [
              _Item(
                icon: Icons.star_outline_rounded,
                title: 'Beri Rating & Cek Pembaruan',
                onTap: () => openUrl(context, AppConstants.playStoreUrl),
              ),
              _Item(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () => _push(context, const AboutScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }
}

class _DarkModeSwitch extends StatelessWidget {
  const _DarkModeSwitch();

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferences.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: prefs.themeMode,
      builder: (context, mode, _) {
        final isDark = switch (mode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        return _ItemTile(
          icon: isDark ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
          title: 'Mode Gelap',
          subtitle: mode == ThemeMode.system
              ? 'Mengikuti pengaturan perangkat'
              : null,
          onTap: () =>
              prefs.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
          trailing: Switch(
            value: isDark,
            onChanged: (value) =>
                prefs.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ItemTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: scheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
      trailing: trailing,
    );
  }
}
