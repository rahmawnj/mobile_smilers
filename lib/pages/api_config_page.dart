import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'api_login_page.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    if (!mounted) return;
    _controller.text = baseUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    final normalized = ApiConfig.normalize(value);
    final uri = Uri.tryParse(normalized);

    await ApiService.instance.clearStoredAppInfo();

    if (value.isEmpty ||
        normalized.isEmpty ||
        uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _show(
        'URL tidak valid. Contoh: https://server-rumah-sakit.com atau http://192.168.1.100',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiConfig.saveBaseUrl(normalized);
      await ApiService.instance.getAppInfo();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ApiLoginPage()),
      );
    } on ApiException catch (e) {
      if (mounted) _show(e.message);
    } catch (_) {
      if (mounted) {
        _show('Tidak dapat mengambil informasi aplikasi dari server.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe5ebf1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xffeaf2ff),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dns_outlined,
                            color: Color(0xff1261dc),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konfigurasi Server',
                                style: TextStyle(
                                  color: Color(0xff334454),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Atur alamat server API rumah sakit.',
                                style: TextStyle(
                                  color: Color(0xff8b99a5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Base URL',
                      style: TextStyle(
                        color: Color(0xff52616f),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 46,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                        style: const TextStyle(
                          color: Color(0xff465564),
                          fontSize: 11,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://server-rumah-sakit.com',
                          hintStyle: const TextStyle(
                            color: Color(0xff9aa8b5),
                            fontSize: 10,
                          ),
                          prefixIcon: const Icon(
                            Icons.dns_outlined,
                            color: Color(0xff7f8c98),
                            size: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffe5ebf1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffe5ebf1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xff1261dc),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Contoh: https://server-rumah-sakit.com atau http://192.168.1.100',
                      style: TextStyle(
                        color: Color(0xff9aa8b5),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          _saving ? 'Menyimpan...' : 'Simpan & Lanjut',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1261dc),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xff9fbbe4),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'URL disimpan di perangkat ini dan dipakai untuk seluruh request API.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xff9aa8b5),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
