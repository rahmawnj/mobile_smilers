import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class ManualBookPage extends StatelessWidget {
  const ManualBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 170,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff5cc9bd), Color(0xff159cf1)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -55,
                    top: -70,
                    child: Container(
                      width: 170, height: 170,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .10)),
                    ),
                  ),
                  Positioned(
                    left: -75,
                    bottom: -105,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBackButton(),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MANUAL BOOK',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.3),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Panduan penggunaan aplikasi SmileRS',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: _ManualContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualContent extends StatelessWidget {
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Panduan Penggunaan',style: TextStyle(color: Color(0xff34495e),fontSize:16,fontWeight: FontWeight.w800)),
    SizedBox(height:5), Text('Pelajari fitur utama SmileRS dengan langkah sederhana.',style: TextStyle(color: Color(0xff8b99a5),fontSize:10)),
    SizedBox(height:20),
    _ManualSection(icon:Icons.login_rounded,title:'1. Login',text:'Masuk menggunakan username dan kata sandi yang diberikan administrator.'),
    _ManualSection(icon:Icons.dashboard_rounded,title:'2. Dashboard',text:'Lihat ringkasan data linen, transaksi, serta keluar masuk linen dan tirai.'),
    _ManualSection(icon:Icons.inventory_2_outlined,title:'3. Data Linen',text:'Gunakan Ready, Laundry, dan Ruangan untuk melihat data linen berdasarkan status dan lokasi.'),
    _ManualSection(icon:Icons.swap_horiz_rounded,title:'4. Keluar Masuk',text:'Pantau transaksi linen keluar dan masuk berdasarkan ruangan.'),
    _ManualSection(icon:Icons.qr_code_scanner_rounded,title:'5. Scan QR Code',text:'Periksa identitas, status, kategori, dan posisi terakhir linen melalui QR Code.'),
    _ManualSection(icon:Icons.assignment_rounded,title:'6. Permintaan Linen',text:'Buat dan pantau permintaan linen sesuai kebutuhan ruangan.'),
    _ManualSection(icon:Icons.bar_chart_rounded,title:'7. Rekap Transaksi',text:'Lihat rangkuman transaksi linen dan tirai yang tersedia pada sistem.'),
  ]);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xffeef7ff),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xff159cf1),
              size: 19,
            ),
          ),
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
                    color: Color(0xff8b99a5),
                    fontSize: 10,
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
