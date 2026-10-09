import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_service.dart';
import 'pages/api_config_page.dart';
import 'pages/api_login_page.dart';
import 'pages/dashboard_page.dart';
import 'widgets/shared_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasServerUrl = await ApiConfig.hasSavedBaseUrl();
  runApp(MyApp(showConfigFirst: !hasServerUrl));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.showConfigFirst});

  final bool showConfigFirst;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smile RS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18bdd7)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfff5f8fc),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          labelStyle: const TextStyle(
            color: Color(0xff465564),
            fontSize: 12,
          ),
          hintStyle: const TextStyle(
            color: Color(0xff8a98a5),
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffd9e0e7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffd9e0e7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xff1261dc),
              width: 1.2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffe5e9ee)),
          ),
        ),
      ),
      // Tampilkan halaman konfigurasi langsung jika URL server belum disimpan.
      // AppStartupPage hanya dipakai untuk memvalidasi konfigurasi yang sudah ada.
      home: showConfigFirst ? const ApiConfigPage() : const AppStartupPage(),
    );
  }
}

class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key});

  @override
  State<AppStartupPage> createState() => _AppStartupPageState();
}

class _AppStartupPageState extends State<AppStartupPage> {
  @override
  void initState() {
    super.initState();
    _openInitialPage();
  }

  Future<void> _openInitialPage() async {
    final configured = await ApiConfig.hasSavedBaseUrl();

    if (!configured) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ApiConfigPage()),
      );
      return;
    }

    // URL yang pernah berhasil disimpan tetap dipakai.
    // Setiap kali app dibuka, cek kembali /app-info.
    // Kalau Remember Me aktif dan token masih valid, langsung masuk dashboard.
    try {
      await ApiService.instance.getAppInfo();

      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final token = await ApiService.instance.getToken();

      if (rememberMe && token != null && token.isNotEmpty) {
        try {
          final user = await ApiService.instance.me();

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AppShell(
                userName: user.name,
                activeIndex: 0,
                body: DashboardPage(
                  userName: user.name,
                  embedded: true,
                ),
              ),
            ),
          );
          return;
        } catch (_) {
          await ApiService.instance.clearSession();
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ApiLoginPage()),
      );
    } catch (_) {
      await ApiService.instance.clearStoredAppInfo();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ApiConfigPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // No custom splash artwork; keep a plain background while startup checks run.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}
