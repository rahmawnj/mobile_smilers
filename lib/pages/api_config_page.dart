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

    // Setiap kali user menekan update, branding lama langsung dihapus.
    // Jika URL baru gagal diakses / app-info gagal diambil, nama dan logo
    // lama tidak akan tetap tampil.
    await ApiService.instance.clearStoredAppInfo();

    if (value.isEmpty || normalized.isEmpty || uri == null || uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _show('URL tidak valid. Contoh: https://smilers.co.id');
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
      if (mounted) {
        _show(e.message);
      }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff45D3B0),
              Color(0xff55D5C8),
              Color(0xff3EB9D7),
              Color(0xff55A9E8),
            ],
            stops: [0.0, 0.38, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 370),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .97),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .20),
                        blurRadius: 35,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: const Color(0xff118D9A).withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.dns_rounded,
                          color: Color(0xff118D9A),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'KONFIGURASI SERVER',
                        style: TextStyle(color: Color(0xff173A58), fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Masukkan alamat server rumah sakit terlebih dahulu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xff8291A0), fontSize: 11),
                      ),
                      const SizedBox(height: 25),
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
                            hintText: 'https://smilers.co.id',
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
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Contoh: https://smilers.co.id', style: TextStyle(color: Color(0xff94A2AC), fontSize: 10)),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Menyimpan...' : 'Simpan & Lanjut'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6CD4C5),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xffA9DED7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      ),
    );
  }
}
