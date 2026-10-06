import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class QrCodeCheckPage extends StatefulWidget {
  const QrCodeCheckPage({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  State<QrCodeCheckPage> createState() => _QrCodeCheckPageState();
}

class _QrCodeCheckPageState extends State<QrCodeCheckPage> {
  final TextEditingController _qrController = TextEditingController();
  LinenQrCheckResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _checkQr() async {
    final qr = _qrController.text.trim();
    if (qr.isEmpty) {
      setState(() => _error = 'Masukkan QR Code terlebih dahulu.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await ApiService.instance.checkLinenQr(qr);
      if (!mounted) return;
      setState(() { _result = result; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Gagal melakukan pengecekan QR Code.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(title: 'QR Code Check', userName: widget.userName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionCard(
                          title: 'Kolom Input Utama',
                          child: Column(
                            children: [
                              TextField(
                                controller: _qrController,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _checkQr(),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan QR Code',
                                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xffe29c02)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffdce4ec))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffdce4ec))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffe29c02), width: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xfffff1f1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffffd1d1))),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xffd93025), size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xffb42318), fontSize: 12, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        ],
                        if (result != null) ...[
                          const SizedBox(height: 14),
                          _QrResultCard(result: result),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _QrResultCard extends StatelessWidget {
  const _QrResultCard({required this.result});
  final LinenQrCheckResult result;

  String _formatLastPosition(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final raw = value.trim();
    if (!raw.startsWith('{') || !raw.endsWith('}')) return raw;

    final normalized = raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map((part) {
          final separator = part.indexOf(':');
          if (separator == -1) return part;
          final key = part.substring(0, separator).trim();
          final val = part.substring(separator + 1).trim();
          switch (key) {
            case 'nama ruangan':
              return val;
            case 'tanggal_keluar':
              return 'Keluar: $val';
            case 'tanggal_masuk':
              return 'Masuk: $val';
            default:
              return '$key: $val';
          }
        })
        .join('\n');

    return normalized.isEmpty ? '-' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final status = result.status.isEmpty ? '-' : result.status;
    return DashboardCard(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xfff7f9fc), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffe3e9ef))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xffe29c02).withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.qr_code_2_rounded, color: Color(0xffe29c02))),
                const SizedBox(width: 11),
                const Expanded(child: Text('Hasil QR Code Check', style: TextStyle(color: Color(0xff263645), fontSize: 15, fontWeight: FontWeight.w800))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xff0e57ed).withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(color: Color(0xff0e57ed), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(result.namaLinen.isEmpty ? '-' : result.namaLinen, style: const TextStyle(color: Color(0xff263645), fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _ResultRow(label: 'QR Code', value: result.qrCode),
            _ResultRow(label: 'Tag RFID', value: result.tagRfid),
            _ResultRow(label: 'Kategori', value: result.kategori),
            _ResultRow(label: 'Berat', value: result.berat + ' kg'),
            _ResultRow(label: 'Total Pemakaian', value: result.totalPemakaian.toString() + ' kali'),
            _ResultRow(label: 'Posisi Terakhir', value: _formatLastPosition(result.lastPosition)),
            _ResultRow(label: 'Tanggal Input', value: result.tglInput),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text(label, style: const TextStyle(color: Color(0xff7d8c99), fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(color: Color(0xff465564), fontSize: 11, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff34495e),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Belum ada data',
            filled: true,
            fillColor: const Color(0xfff5f6f8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xffe1e6eb),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xffe1e6eb),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
