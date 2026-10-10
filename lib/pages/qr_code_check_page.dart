import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../api/api_service.dart';

class QrCodeCheckPage extends StatefulWidget {
  const QrCodeCheckPage({super.key, required this.userName});
  final String userName;

  @override
  State<QrCodeCheckPage> createState() => _QrCodeCheckPageState();
}

class _QrCodeCheckPageState extends State<QrCodeCheckPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  late final AnimationController _scanLine;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        code = value;
        break;
      }
    }
    if (code == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _scanner.stop();
    try {
      final result = await ApiService.instance.checkLinenQr(code);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _QrResultPage(userName: widget.userName, result: result),
      ));
      if (!mounted) return;
      setState(() => _processing = false);
      await _scanner.start();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _processing = false;
      });
      await _scanner.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memeriksa QR Code. Silakan pindai kembali.';
        _processing = false;
      });
      await _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101820),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 14),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan QR Linen', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Kamera aktif otomatis', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )),
                IconButton(
                  tooltip: 'Ganti kamera',
                  onPressed: () => _scanner.switchCamera(),
                  icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Flash',
                  onPressed: () => _scanner.toggleTorch(),
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                ),
              ]),
            ),
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: const Color(0xff17212b),
                    padding: const EdgeInsets.all(28),
                    child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
                        const SizedBox(height: 14),
                        const Text('Kamera tidak dapat dibuka', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          error.errorCode == MobileScannerErrorCode.permissionDenied
                              ? 'Akses kamera diperlukan untuk scan QR. Tekan tombol di bawah untuk mencoba meminta izin lagi. Jika izin pernah ditolak permanen, aktifkan Kamera melalui Pengaturan aplikasi.'
                              : 'Periksa izin kamera atau tutup aplikasi lain yang sedang menggunakan kamera.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await _scanner.start();
                            } catch (_) {
                              if (mounted) {
                                setState(() {
                                  _error = 'Izin kamera belum aktif. Buka Pengaturan aplikasi, izinkan Kamera, lalu coba lagi.';
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Izinkan / Coba kamera lagi'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff02c0cc),
                            foregroundColor: const Color(0xff101820),
                          ),
                        ),
                      ],
                    )),
                  ),
                  placeholderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xff02c0cc))),
                ),
                IgnorePointer(child: Center(child: LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth * .76;
                  final height = width * .76;
                  return Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: .3)),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _ScanCornersPainter())),
                      AnimatedBuilder(
                        animation: _scanLine,
                        builder: (_, __) => Positioned(
                          left: 12,
                          right: 12,
                          top: 12 + (height - 24) * _scanLine.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xff02e6d0),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: const Color(0xff02e6d0).withValues(alpha: .7), blurRadius: 12, spreadRadius: 2)],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  );
                }))),
                if (_processing) Container(
                  color: Colors.black.withValues(alpha: .65),
                  child: const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xff02c0cc)),
                      SizedBox(height: 16),
                      Text('QR terbaca, mengambil data...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  )),
                ),
              ]),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              decoration: const BoxDecoration(color: Color(0xff17212b), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(children: [
                if (_error != null) Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: const Color(0xff512d31), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const Icon(Icons.qr_code_scanner_rounded, color: Color(0xff02c0cc), size: 30),
                const SizedBox(height: 10),
                Text(
                  _processing ? 'Sedang memproses QR Code' : 'Posisikan QR di dalam kotak',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text('Pemindaian otomatis. Hasil akan terbuka setelah QR berhasil dibaca.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrResultPage extends StatelessWidget {
  const _QrResultPage({required this.userName, required this.result});
  final String userName;
  final LinenQrCheckResult result;

  String _position(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final raw = value.trim();
    if (!raw.startsWith('{') || !raw.endsWith('}')) return raw;
    return raw.replaceAll('{', '').replaceAll('}', '').split(',').map((part) {
      final p = part.trim();
      final i = p.indexOf(':');
      if (i < 0) return p;
      final key = p.substring(0, i).trim();
      final val = p.substring(i + 1).trim();
      if (key == 'nama ruangan') return val;
      if (key == 'tanggal_keluar') return 'Keluar: $val';
      if (key == 'tanggal_masuk') return 'Masuk: $val';
      return '$key: $val';
    }).where((s) => s.isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('QR Code', result.qrCode),
      MapEntry('Tag RFID', result.tagRfid),
      MapEntry('Kategori', result.kategori),
      MapEntry('Berat', '${result.berat} kg'),
      MapEntry('Total Pemakaian', '${result.totalPemakaian} kali'),
      MapEntry('Posisi Terakhir', _position(result.lastPosition)),
      MapEntry('Tanggal Input', result.tglInput),
    ];
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(title: const Text('Hasil QR Code'), backgroundColor: Colors.white, foregroundColor: const Color(0xff263645), elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe3e9ef))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xff02c0cc).withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.qr_code_2_rounded, color: Color(0xff02aab6), size: 26)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Data linen ditemukan', style: TextStyle(color: Color(0xff263645), fontSize: 16, fontWeight: FontWeight.w800))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xff0e57ed).withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(result.status.isEmpty ? '-' : result.status, style: const TextStyle(color: Color(0xff0e57ed), fontSize: 11, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 22),
            Text(result.namaLinen.isEmpty ? '-' : result.namaLinen, style: const TextStyle(color: Color(0xff263645), fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 132, child: Text(row.key, style: const TextStyle(color: Color(0xff7d8c99), fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text(row.value.isEmpty ? '-' : row.value, style: const TextStyle(color: Color(0xff465564), fontSize: 12, fontWeight: FontWeight.w700, height: 1.4))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan QR Berikutnya'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff0e57ed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const length = 28.0;
    const radius = 3.0;
    final paint = Paint()..color = const Color(0xff02e6d0)..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(2, length)..lineTo(2, radius)..quadraticBezierTo(2, 2, radius, 2)..lineTo(length, 2)
      ..moveTo(size.width - length, 2)..lineTo(size.width - radius, 2)..quadraticBezierTo(size.width - 2, 2, size.width - 2, radius)..lineTo(size.width - 2, length)
      ..moveTo(2, size.height - length)..lineTo(2, size.height - radius)..quadraticBezierTo(2, size.height - 2, radius, size.height - 2)..lineTo(length, size.height - 2)
      ..moveTo(size.width - length, size.height - 2)..lineTo(size.width - radius, size.height - 2)..quadraticBezierTo(size.width - 2, size.height - 2, size.width - 2, size.height - radius)..lineTo(size.width - 2, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
