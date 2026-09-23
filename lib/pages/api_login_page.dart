import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';

import '../api/api_service.dart';
import 'dashboard_page.dart';
import 'stream_page.dart';
import 'api_config_page.dart';

class ApiLoginPage extends StatefulWidget {
  const ApiLoginPage({super.key});

  @override
  State<ApiLoginPage> createState() => _ApiLoginPageState();
}

class _ApiLoginPageState extends State<ApiLoginPage> {
  final _usernameController = TextEditingController(text: 'superadmin');
  final _passwordController = TextEditingController(text: 'password');

  bool _obscurePassword = true;
  bool _isLoading = false;
  AppInfo? _appInfo;
  String _appLogoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await ApiService.instance.getStoredAppInfo();
      final baseUrl = await ApiConfig.getBaseUrl();
      if (!mounted) return;
      if (info != null) {
        setState(() {
          _appInfo = info;
          _appLogoUrl = info.logoUrl(baseUrl);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showMessage('Username belum diisi.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Password belum diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.instance.login(
        username: username,
        password: password,
        deviceName: 'mobile-app',
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            userName: result.user.name,
            activeIndex: 0,
            body: DashboardPage(
              userName: result.user.name,
              embedded: true,
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Tidak dapat terhubung ke server. Periksa Base URL dan koneksi internet.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xff18324A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
              Color(0xff0D7F83),
              Color(0xff167FA5),
              Color(0xff174D83),
              Color(0xff122F58),
            ],
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
                    borderRadius: BorderRadius.circular(24),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          _appLogoUrl,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _appInfo?.appName.isNotEmpty == true ? _appInfo!.appName : 'APLIKASI',
                        style: TextStyle(
                          color: Color(0xff173A58),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hospital Management System',
                        style: TextStyle(
                          color: Color(0xff8291A0),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Username',
                          Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _login(),
                        decoration: _inputDecoration(
                          'Password',
                          Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xff8291A0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(_isLoading ? 'Menghubungkan...' : 'Masuk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1197A2),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xff9bbec2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StreamPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: const Text('Stream'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff118D9A),
                            side: const BorderSide(color: Color(0xff118D9A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Konfigurasi Server',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ApiConfigPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Color(0xff118D9A),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _appInfo?.appName.isNotEmpty == true ? _appInfo!.appName : '',
                        style: TextStyle(
                          color: Color(0xffA0ADB6),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
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

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xff118D9A)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xffF5F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff118D9A)),
      ),
    );
  }
}
