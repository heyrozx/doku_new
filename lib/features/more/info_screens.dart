import 'package:doku/core/constants.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/features/more/more_page.dart';
import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    (
      'Apa itu aplikasi DOKU?',
      'DOKU (Dompet Saku) adalah aplikasi catatan keuangan pribadi untuk membantu kamu mencatat dan mengelola pemasukan serta pengeluaran.',
    ),
    (
      'Bagaimana cara menggunakan DOKU?',
      'Tekan tombol "Tambah" di halaman Beranda atau Transaksi, pilih jenis transaksi, isi jumlah, kategori, dan tanggal, lalu simpan. Tanpa perlu membuat akun.',
    ),
    (
      'Bagaimana cara mengubah atau menghapus transaksi?',
      'Ketuk transaksi untuk mengubahnya, lalu gunakan ikon hapus di kanan atas untuk menghapus. Tekan lama judul tanggal di halaman Transaksi untuk menghapus semua transaksi di tanggal tersebut.',
    ),
    (
      'Apakah DOKU aman digunakan?',
      'Ya. Data yang kamu masukkan disimpan secara lokal di perangkat Android-mu dan tidak dibagikan kepada pihak ketiga.',
    ),
    (
      'Apakah DOKU menyediakan laporan keuangan?',
      'Ya. Menu Laporan menampilkan ringkasan mingguan, bulanan, tahunan, atau seluruh waktu, lengkap dengan grafik dan rincian per kategori. Laporan juga bisa diunduh sebagai file Excel.',
    ),
    (
      'Bagaimana cara memindahkan data ke HP lain?',
      'Unduh laporan "Semua" dalam format Excel dari menu Laporan, lalu buka menu Pengaturan > Impor Excel di perangkat baru.',
    ),
    (
      'Apakah DOKU mengirimkan data saya ke server?',
      'Tidak. Semua data transaksi disimpan secara lokal di perangkatmu.',
    ),
    (
      'Apakah DOKU tersedia untuk platform lain?',
      'Saat ini DOKU hanya tersedia untuk Android.',
    ),
    (
      'Bagaimana cara menghubungi tim dukungan?',
      'Kirim email ke ${AppConstants.supportEmail} atau gunakan menu Kritik & Saran.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (question, answer) in _faqs)
                    ExpansionTile(
                      title: Text(
                        question,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.centerLeft,
                      children: [
                        Text(
                          answer,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const _sections = [
    (
      'Disclaimer Aplikasi DOKU',
      'Aplikasi DOKU merupakan aplikasi catatan keuangan pribadi yang dirancang untuk membantu pengguna dalam mencatat dan mengelola pemasukan serta pengeluaran keuangan mereka. Aplikasi ini tidak berhubungan dengan keuangan tunai bank manapun, baik bank konvensional maupun bank digital.',
    ),
    (
      'Penyimpanan Data',
      'Data yang dimasukkan oleh pengguna ke dalam aplikasi DOKU disimpan secara lokal pada perangkat Android pengguna. Aplikasi tidak mengirimkan data ke server eksternal atau pihak ketiga. Pengguna bertanggung jawab penuh atas keamanan dan backup data mereka sendiri.',
    ),
    (
      'Privasi Pengguna',
      'Privasi pengguna sangat penting bagi kami. Aplikasi DOKU tidak mengumpulkan, menyimpan, atau membagikan informasi pribadi pengguna tanpa izin. Kami tidak menyimpan informasi login, nomor rekening, atau informasi keuangan pribadi lainnya dalam aplikasi.',
    ),
    (
      'Konsultasi Keuangan',
      'Aplikasi DOKU dirancang untuk memberikan bantuan dalam pencatatan keuangan pribadi. Meskipun demikian, pengguna disarankan untuk tetap berkonsultasi dengan profesional keuangan sebelum membuat keputusan keuangan yang penting.',
    ),
    (
      'Penggunaan Informasi',
      'Informasi yang disediakan oleh aplikasi DOKU hanya bersifat informatif dan tidak boleh dijadikan sebagai saran atau rekomendasi keuangan. Pengguna bertanggung jawab sepenuhnya atas keputusan keuangan yang diambil berdasarkan informasi dalam aplikasi.',
    ),
    (
      'Perubahan dan Perbaikan',
      'Kami berusaha untuk terus memperbarui dan meningkatkan aplikasi DOKU. Namun, kami tidak bertanggung jawab atas kerugian atau kerusakan yang disebabkan oleh penggunaan atau ketergantungan pada informasi yang disediakan dalam aplikasi.',
    ),
    (
      'Kontak',
      'Jika Anda memiliki pertanyaan atau masukan tentang aplikasi DOKU, jangan ragu untuk menghubungi kami di ${AppConstants.supportEmail}.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final (title, body) in _sections) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Dengan menggunakan aplikasi DOKU, pengguna dianggap telah membaca, memahami, dan menyetujui disclaimer ini. Kami sarankan untuk membaca disclaimer ini secara berkala untuk memahami perubahan atau tambahan yang mungkin terjadi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    (Icons.swap_vert_rounded, 'Catat pemasukan & pengeluaran'),
    (Icons.label_outline_rounded, 'Kategori yang bisa diatur sendiri'),
    (
      Icons.insert_chart_outlined_rounded,
      'Laporan mingguan, bulanan & tahunan',
    ),
    (Icons.pie_chart_outline_rounded, 'Grafik tren & rincian kategori'),
    (Icons.table_view_rounded, 'Ekspor & impor Excel'),
    (Icons.dark_mode_outlined, 'Mode gelap otomatis atau manual'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 96,
                height: 96,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${AppConstants.appName} — ${AppConstants.appFullName}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'DOKU (Dompet Saku) membantu kamu mengelola pemasukan dan pengeluaran setiap hari, '
            'mulai dari gaji bulanan, uang saku, dan hadiah, hingga biaya listrik, makan, dan belanja. '
            'Dengan mencatat setiap transaksi, kamu bisa melacak ke mana uangmu pergi dan menjadi lebih hemat.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (icon, label) in _features)
                  ListTile(
                    leading: Icon(icon, color: theme.colorScheme.primary),
                    title: Text(label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Dikembangkan oleh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.companyName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perusahaan apps & services yang membangun dan '
                        'mengoperasikan platform digital untuk bisnis dan '
                        'keseharian.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(AppConstants.companyLocation),
                ),
                ListTile(
                  onTap: () =>
                      MorePage.openUrl(context, AppConstants.companyWebsite),
                  leading: Icon(
                    Icons.language_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('nexadream.id'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
                ListTile(
                  onTap: () => MorePage.openUrl(
                    context,
                    'mailto:${AppConstants.supportEmail}',
                  ),
                  leading: Icon(
                    Icons.mail_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(AppConstants.supportEmail),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} ${AppConstants.companyName}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
