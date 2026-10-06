import 'package:flutter/material.dart';

class AboutSmileRsPage extends StatelessWidget {
  const AboutSmileRsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        backgroundColor: const Color(0xff1261dc),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tentang SmileRS',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf2ff),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xff1261dc),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SmileRS',
                  style: TextStyle(
                    color: Color(0xff172b4d),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistem Manajemen Linen Rumah Sakit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff7d8c99),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SmileRS merupakan aplikasi untuk membantu pengelolaan linen dan tirai rumah sakit secara terintegrasi, mulai dari pemantauan stok dan posisi linen hingga pencatatan transaksi keluar masuk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff526273),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AboutItem(
            icon: Icons.inventory_2_outlined,
            title: 'Manajemen Linen',
            text: 'Memantau linen berdasarkan status Ready, Laundry, dan Ruangan.',
          ),
          _AboutItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Transaksi',
            text: 'Mencatat dan memantau pergerakan linen serta tirai keluar dan masuk.',
          ),
          _AboutItem(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Identifikasi Linen',
            text: 'Mendukung pemeriksaan linen menggunakan QR Code.',
          ),
          _AboutItem(
            icon: Icons.analytics_outlined,
            title: 'Monitoring',
            text: 'Menyediakan ringkasan dan rekap data untuk membantu monitoring operasional.',
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe8edf3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff1261dc), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff34495e),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xff7d8c99),
                    fontSize: 9,
                    height: 1.4,
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
