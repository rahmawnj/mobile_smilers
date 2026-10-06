import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class AboutSmileRsPage extends StatelessWidget {
  const AboutSmileRsPage({super.key});

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
                        AppBackButton(),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TENTANG SMILERS',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.3),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Informasi aplikasi SmileRS',
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
                  child: _AboutContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  @override Widget build(BuildContext context) => Column(children: [
    Icon(Icons.local_hospital_rounded,color: Color(0xff159cf1),size:48),
    SizedBox(height:12),
    Text('SmileRS',style:TextStyle(color:Color(0xff34495e),fontSize:22,fontWeight:FontWeight.w900)),
    SizedBox(height:4),
    Text('Sistem Manajemen Linen Rumah Sakit',textAlign:TextAlign.center,style:TextStyle(color:Color(0xff8b99a5),fontSize:10,fontWeight:FontWeight.w600)),
    SizedBox(height:20),
    Divider(height:1,color:Color(0xffedf1f5)),
    SizedBox(height:18),
    Text('SmileRS merupakan aplikasi untuk membantu pengelolaan linen dan tirai rumah sakit secara terintegrasi, mulai dari pemantauan data hingga pencatatan transaksi keluar masuk.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xff526273),fontSize:11,height:1.6)),
    SizedBox(height:22),
    _AboutItem(icon:Icons.inventory_2_outlined,title:'Manajemen Linen',text:'Memantau linen Ready, Laundry, dan Ruangan.'),
    _AboutItem(icon:Icons.swap_horiz_rounded,title:'Transaksi',text:'Mencatat pergerakan linen dan tirai keluar masuk.'),
    _AboutItem(icon:Icons.qr_code_scanner_rounded,title:'Identifikasi Linen',text:'Mendukung pemeriksaan linen menggunakan QR Code.'),
    _AboutItem(icon:Icons.analytics_outlined,title:'Monitoring',text:'Menyediakan ringkasan dan rekap untuk monitoring operasional.'),
  ]);
}


class _AboutItem extends StatelessWidget {
  const _AboutItem({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
            child: Icon(icon, color: const Color(0xff159cf1), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xff34495e), fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(color: Color(0xff8b99a5), fontSize: 10, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
