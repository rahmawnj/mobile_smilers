import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'api_login_page.dart';
import '../widgets/shared_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await ApiService.instance.logout();
    } catch (_) {
      await ApiService.instance.clearSession();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApiLoginPage()),
      (_) => false,
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        title: const Text(
          'SETTING',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff34495e),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 44),
        children: [
          _SettingMenu(
            icon: Icons.lock_outline_rounded,
            title: 'Ganti Sandi',
            subtitle: 'Ubah kata sandi akun Anda',
            onTap: () => _showInfo(
              'Ganti Sandi',
              'Halaman ganti sandi akan tersedia di sini.',
            ),
          ),
          const SizedBox(height: 10),
          _SettingMenu(
            icon: Icons.menu_book_outlined,
            title: 'Manual Book',
            subtitle: 'Panduan penggunaan aplikasi SmileRS',
            onTap: () => _showInfo(
              'Manual Book',
              'Panduan penggunaan aplikasi akan tersedia di sini.',
            ),
          ),
          const SizedBox(height: 10),
          _SettingMenu(
            icon: Icons.info_outline_rounded,
            title: 'Tentang SmileRS',
            subtitle: 'Informasi tentang aplikasi SmileRS',
            onTap: () => _showInfo(
              'Tentang SmileRS',
              'SmileRS adalah sistem manajemen linen untuk rumah sakit.',
            ),
          ),
          const SizedBox(height: 54),
          Center(
            child: SizedBox(
              width: 190,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoggingOut ? null : _logout,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xffe85d5d),
                  disabledBackgroundColor: const Color(0xffe8a1a1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingMenu extends StatelessWidget {
  const _SettingMenu({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xff159cf1).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff159cf1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff34495e),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff8b99a5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xffa5b0ba),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
