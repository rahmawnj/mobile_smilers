import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = false;
  bool _isLoading = false;
  AppInfo? _appInfo;
  String _appLogoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _rememberMe = prefs.getBool('remember_me') ?? false);
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 8,
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
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _appLogoUrl.isEmpty
                                ? const SizedBox(
                                    width: 82,
                                    height: 82,
                                    child: Icon(
                                      Icons.local_hospital_rounded,
                                      color: Color(0xff159cf1),
                                    ),
                                  )
                                : Image.network(
                                    _appLogoUrl,
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Color(0xff159cf1),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _appInfo?.appName.isNotEmpty == true
                                ? _appInfo!.appName
                                : 'SmileRS',
                            style: const TextStyle(
                              color: Color(0xff173A58),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(
                                      () => _rememberMe = value ?? false,
                                    );
                                  },
                                  activeColor: const Color(0xff118D9A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xffB5C0C9),
                                    width: 1.4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Color(0xff526575),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                              label: Text(
                                _isLoading ? 'Menghubungkan...' : 'Masuk',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff6CD4C5),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xffA9DED7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const StreamPage(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                              ),
                              label: const Text('Stream Linen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff3BA9FD),
                                foregroundColor: Colors.white,
                                elevation: 0,
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
                  const SizedBox(height: 8),
                  const Text(
                    '© New SmileRS 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Support by PT Anugerah Global',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff118D9A)),
      ),
    );
  }
}
