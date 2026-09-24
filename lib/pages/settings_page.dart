import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'api_login_page.dart';

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
  late Future<AuthUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<AuthUser?> _loadUser() async {
    try {
      return await ApiService.instance.me();
    } catch (_) {
      return await ApiService.instance.getSavedUser();
    }
  }

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
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<AuthUser?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final name = user?.name.trim().isNotEmpty == true
                ? user!.name
                : widget.userName;
            final username = user?.username ?? '';
            final role = user?.roles.isNotEmpty == true
                ? user!.roles.first
                : 'User';
            final foto = user?.foto;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _SettingsHero(
                  name: name,
                  role: role,
                ),
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _ProfileCard(
                      name: name,
                      username: username,
                      role: role,
                      foto: foto,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 42),
                    child: Column(
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
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 190,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoggingOut ? null : _logout,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xffe85d5d),
                              disabledBackgroundColor:
                                  const Color(0xffe8a1a1),
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff5cc9bd),
            Color(0xff159cf1),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -70,
            child: _HeroCircle(
              size: 170,
              opacity: .10,
            ),
          ),
          Positioned(
            left: -75,
            bottom: -100,
            child: _HeroCircle(
              size: 180,
              opacity: .08,
            ),
          ),
          Positioned(
            right: 55,
            bottom: -90,
            child: _HeroCircle(
              size: 160,
              opacity: .06,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(13),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SETTING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kelola akun dan pengaturan SmileRS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.username,
    required this.role,
    required this.foto,
  });

  final String name;
  final String username;
  final String role;
  final String? foto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProfileAvatar(foto: foto, name: name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff34495e),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff8b99a5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff159cf1).withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xff159cf1),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: Color(0xff159cf1),
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.foto,
    required this.name,
  });

  final String? foto;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 62,
        height: 62,
        color: const Color(0xffeaf5fc),
        child: foto != null && foto!.trim().isNotEmpty
            ? Image.network(
                foto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                  text: fallback,
                ),
              )
            : _AvatarFallback(text: fallback),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xff159cf1),
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0xff159cf1).withValues(alpha: .045),
        splashColor: const Color(0xff159cf1).withValues(alpha: .08),
        highlightColor: const Color(0xff159cf1).withValues(alpha: .035),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xffe3e9ee),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xff159cf1).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff159cf1),
                  size: 21,
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
                    const SizedBox(height: 3),
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
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

