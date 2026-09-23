import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'pages/api_config_page.dart';
import 'pages/api_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smile RS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18bdd7)),
      ),
      home: const AppStartupPage(),
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
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => configured
            ? const ApiLoginPage()
            : const ApiConfigPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xff118D9A),
        ),
      ),
    );
  }
}
