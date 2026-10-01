import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<AuthUser> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService.instance.me();
  }

  Future<void> _refresh() async {
    setState(() => _userFuture = ApiService.instance.me());
    await _userFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<AuthUser>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff159cf1)),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                children: [
                  _ProfileHeader(onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_outlined,
                                color: Color(0xff8b99a5), size: 42),
                            const SizedBox(height: 12),
                            const Text(
                              'Data akun tidak dapat dimuat.',
                              style: TextStyle(
                                color: Color(0xff34495e),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final user = snapshot.data!;
            final role = user.roles.isEmpty ? 'User' : user.roles.join(', ');

            return RefreshIndicator(
              color: const Color(0xff159cf1),
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileHeader(onBack: () => Navigator.of(context).pop()),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .09),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _Avatar(foto: user.foto, name: user.name),
                            const SizedBox(height: 18),
                            Text(
                              user.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xff34495e),
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                color: Color(0xff8b99a5),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff159cf1)
                                    .withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xff159cf1),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(
                              height: 1,
                              color: Color(0xffedf1f5),
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'ID',
                              value: user.id.toString(),
                            ),
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Nama',
                              value: user.name,
                            ),
                            _InfoRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Username',
                              value: user.username,
                            ),
                            _InfoRow(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Role',
                              value: role,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5cc9bd), Color(0xff159cf1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .10),
              ),
            ),
          ),
          Positioned(
            left: -75,
            bottom: -105,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(onPressed: onBack),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFIL AKUN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Informasi akun SmileRS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.foto, required this.name});

  final String foto;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 92,
        height: 92,
        color: const Color(0xffeaf5fc),
        child: foto.trim().isNotEmpty
            ? Image.network(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(text: fallback),
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
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff159cf1), size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff8b99a5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xff34495e),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
