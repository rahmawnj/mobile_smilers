import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'api_login_page.dart';
import '../widgets/shared_widgets.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.userName});

  final String userName;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await ApiService.instance.logout();
    } on ApiException catch (e) {
      await ApiService.instance.clearSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      await ApiService.instance.clearSession();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApiLoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      body: Column(
        children: [
          AppBar(title: const Text('ACCOUNT & SETTING')),
          Container(
            height: 164,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xff159cf1),
            child: const Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: 84,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Superadmin'),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text('Rumah Sakit Anugerah Global Sehat'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingItem(
            icon: Icons.key,
            label: 'Ganti Sandi',
            onTap: () => _showInfo(context, 'Ganti Sandi', 'Sandi Baru'),
          ),
          _SettingItem(
            icon: Icons.settings,
            label: 'Manual Book',
            onTap: () => _showInfo(
              context,
              'Manual Book',
              'Panduan penggunaan SMileRS tersedia di sini.',
            ),
          ),
          _SettingItem(
            icon: Icons.text_fields,
            label: 'Tentang SMileRS',
            onTap: () => _showInfo(
              context,
              'Tentang SMileRS',
              'SMileRS - Sistem Manajemen Linen Rumah Sakit.',
            ),
          ),
          _SettingItem(
            icon: Icons.logout,
            label: _isLoggingOut ? 'Keluar...' : 'Keluar',
            onTap: _isLoggingOut ? () {} : _logout,
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
