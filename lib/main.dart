import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'pages/api_config_page.dart';
import 'pages/api_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final baseUrl = await ApiConfig.getBaseUrl();
  runApp(MyApp(hasApiConfig: baseUrl != null && baseUrl.isNotEmpty));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.hasApiConfig});

  final bool hasApiConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smile RS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18bdd7)),
      ),
      home: hasApiConfig ? const ApiLoginPage() : const ApiConfigPage(),
    );
  }
}
