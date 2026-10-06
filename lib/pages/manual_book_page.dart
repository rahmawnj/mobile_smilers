import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class ManualBookPage extends StatelessWidget {
  const ManualBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        backgroundColor: const Color(0xff1261dc),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manual Book',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: const [
          _ManualSection(
            icon: Icons.login_rounded,
            title: '1. Login',
            text: 'Masuk menggunakan username dan kata sandi yang diberikan oleh administrator rumah sakit.',
          ),
          _ManualSection(
            icon: Icons.dashboard_rounded,
            title: '2. Dashboard',
            text: 'Dashboard menampilkan ringkasan data linen, transaksi, serta informasi keluar masuk linen dan tirai.',
          ),
          _ManualSection(
            icon: Icons.inventory_2_outlined,
            title: '3. Data Linen',
            text: 'Gunakan menu Ready, Laundry, dan Ruangan untuk melihat data linen berdasarkan status dan lokasi.',
          ),
          _ManualSection(
            icon: Icons.swap_horiz_rounded,
            title: '4. Keluar Masuk Linen',
            text: 'Gunakan menu Keluar Masuk untuk melihat transaksi linen per ruangan. Detail ruangan juga menampilkan data linen keluar, linen masuk, dan riwayat transaksi.',
          ),
          _ManualSection(
            icon: Icons.qr_code_scanner_rounded,
            title: '5. Scan QR Code',
            text: 'Masukkan atau scan QR Code linen pada halaman pemeriksaan QR untuk melihat identitas, status, kategori, dan posisi terakhir linen.',
          ),
          _ManualSection(
            icon: Icons.assignment_rounded,
            title: '6. Permintaan Linen',
            text: 'Buat permintaan linen dengan memilih ruangan, kategori, dan item yang dibutuhkan. Status permintaan dapat dipantau dari halaman Permintaan.',
          ),
          _ManualSection(
            icon: Icons.bar_chart_rounded,
            title: '7. Rekap Transaksi',
            text: 'Gunakan Rekap Transaksi untuk melihat rangkuman transaksi linen dan tirai sesuai data yang tersedia pada sistem.',
          ),
          _ManualSection(
            icon: Icons.settings_rounded,
            title: '8. Pengaturan',
            text: 'Pada Setting, Anda dapat mengubah profil, mengganti sandi, membuka Manual Book, melihat informasi SmileRS, atau keluar dari akun.',
          ),
        ],
      ),
    );
  }
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xffeaf2ff),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xff1261dc), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff172b4d),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xff667788),
                    fontSize: 10,
                    height: 1.55,
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
