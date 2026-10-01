import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagRfid = _qrController.text;

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: 'QR Code Check',
              userName: widget.userName,
            ),
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
                          child: TextField(
                            controller: _qrController,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Masukkan QR Code',
                              prefixIcon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xff159cf1),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xffdce4ec),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xffdce4ec),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xff159cf1),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Detail',
                          child: Column(
                            children: [
                              _ReadOnlyField(
                                label: 'Nama Linen',
                                value: '',
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Tag RFID',
                                value: tagRfid,
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Kategori',
                                value: '',
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Pemakaian',
                                value: '',
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Posisi Terakhir',
                                value: '',
                              ),
                            ],
                          ),
                        ),
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
