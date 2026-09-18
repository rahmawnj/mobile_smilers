import 'package:flutter/material.dart';

import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_usernameController.text.trim().isEmpty) {
      _showFeedback(
        'Username belum diisi.',
        Icons.person_outline_rounded,
        const Color(0xffef6c6c),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showFeedback(
        'Password belum diisi.',
        Icons.lock_outline_rounded,
        const Color(0xffef6c6c),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 450,
        ),
        pageBuilder: (_, animation, __) => DashboardPage(
          userName: _usernameController.text.trim().isEmpty
              ? 'Rubikah, S.Kep'
              : _usernameController.text.trim(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showFeedback(
    String message,
    IconData icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xff18324A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            stops: [
              0.0,
              0.38,
              0.72,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            const _BackgroundDecoration(),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      (constraints.maxWidth - 32).clamp(
                    280.0,
                    370.0,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        children: [
                          // =========================
                          // TOP BRAND
                          // =========================
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: const _TopBrand(),
                          ),

                          const SizedBox(height: 28),

                          // =========================
                          // LOGIN CARD
                          // =========================
                          Center(
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _LoginCard(
                                  width: cardWidth,
                                  usernameController:
                                      _usernameController,
                                  passwordController:
                                      _passwordController,
                                  rememberMe: _rememberMe,
                                  obscurePassword:
                                      _obscurePassword,
                                  isLoading: _isLoading,
                                  onRememberChanged: (value) {
                                    setState(() {
                                      _rememberMe =
                                          value ?? false;
                                    });
                                  },
                                  onObscureChanged: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  onLogin: _login,
                                  onStreamLinen: () {
                                    _showFeedback(
                                      'Fitur Stream Linen akan segera tersedia.',
                                      Icons
                                          .local_laundry_service_outlined,
                                      const Color(
                                        0xff27CFA0,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // =========================
                          // FOOTER
                          // =========================
                          const _Footer(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   BACKGROUND
   ============================================================ */

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xff53E0C1)
                    .withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xff55B8FF)
                    .withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 170,
            left: -80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .035),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   TOP BRAND
   ============================================================ */

class _TopBrand extends StatelessWidget {
  const _TopBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .20),
              width: 1,
            ),
          ),
          child: const CustomPaint(
            child: const _HospitalLogo(),
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'NEW SMILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'Hospital Management System',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .70),
            fontSize: 9,
            letterSpacing: .7,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   LOGIN CARD
   ============================================================ */

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.width,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isLoading,
    required this.onRememberChanged,
    required this.onObscureChanged,
    required this.onLogin,
    required this.onStreamLinen,
  });

  final double width;

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;

  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onObscureChanged;
  final VoidCallback onLogin;
  final VoidCallback onStreamLinen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(
        25,
        30,
        25,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: .70),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xff00B8B8)
                .withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              color: Color(0xff173A58),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Silahkan login menggunakan akun Anda',
            style: TextStyle(
              color: Color(0xff8291A0),
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 24),

          _LoginField(
            controller: usernameController,
            hint: 'Username',
            prefixIcon:
                Icons.person_outline_rounded,
          ),

          const SizedBox(height: 13),

          _LoginField(
            controller: passwordController,
            hint: 'Password',
            prefixIcon:
                Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            onVisibilityPressed:
                onObscureChanged,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: onRememberChanged,
                  activeColor:
                      const Color(0xff118D9A),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(5),
                  ),
                  side: const BorderSide(
                    color: Color(0xffB5C0C9),
                    width: 1.4,
                  ),
                  visualDensity:
                      VisualDensity.compact,
                ),
              ),

              const SizedBox(width: 4),

              const Text(
                'Remember Me',
                style: TextStyle(
                  color: Color(0xff526575),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                ),
                child: const Text(
                  'Lupa password?',
                  style: TextStyle(
                    color: Color(0xff118D9A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _ActionButton(
            label: 'Masuk',
            icon: Icons.login_rounded,
            color: const Color(0xff1197A2),
            isLoading: isLoading,
            onPressed: onLogin,
          ),

          const SizedBox(height: 11),

          _ActionButton(
            label: 'Stream Linen',
            icon: Icons
                .local_laundry_service_outlined,
            color: const Color(0xff25B989),
            onPressed: onStreamLinen,
          ),

          const SizedBox(height: 19),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xffE7ECEF),
                ),
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'RS ANUGERAH GLOBAL SEHAT',
                  style: TextStyle(
                    color: Color(0xffA0ADB6),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xffE7ECEF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   LOGIN FIELD
   ============================================================ */

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.onVisibilityPressed,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final VoidCallback? onVisibilityPressed;

  @override
  State<_LoginField> createState() =>
      _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: _focused
              ? const Color(0xffF4FBFB)
              : const Color(0xffF4F6F8),
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: _focused
                ? const Color(0xff18A5A7)
                : const Color(0xffE1E7EA),
            width: _focused ? 1.4 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xff18A5A7)
                        .withValues(alpha: .10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          style: const TextStyle(
            color: Color(0xff243D50),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          cursorColor:
              const Color(0xff1197A2),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: Color(0xff9AA8B2),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              size: 19,
              color: _focused
                  ? const Color(0xff1197A2)
                  : const Color(0xff8999A5),
            ),
            suffixIcon:
                widget.onVisibilityPressed ==
                        null
                    ? null
                    : IconButton(
                        onPressed:
                            widget.onVisibilityPressed,
                        splashRadius: 20,
                        icon: Icon(
                          widget.obscureText
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          size: 18,
                          color:
                              const Color(0xff8999A5),
                        ),
                      ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   ACTION BUTTON
   ============================================================ */

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed:
            isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor:
              color.withValues(alpha: .70),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ).copyWith(
          overlayColor:
              WidgetStatePropertyAll(
            Colors.white.withValues(alpha: .12),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/* ============================================================
   FOOTER
   ============================================================ */

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '© New SMILE RS 2026',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white
                .withValues(alpha: .75),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'Support by : PT. Anugerah Global Sukses',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white
                .withValues(alpha: .55),
            fontSize: 7,
          ),
        ),
      ],
    );
  }
}

class _HospitalLogo extends StatelessWidget {
  const _HospitalLogo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        '$url',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
ierTo(
        c.dx - 3,
        c.dy - 1,
        c.dx - 33,
        c.dy - 1,
      )
      ..close();

    canvas.drawPath(
      greenPath,
      green,
    );

    canvas.drawPath(
      bluePath,
      blue,
    );
  }

  @override
  bool shouldRepaint(
    CustomPainter oldDelegate,
  ) {
    return false;
  }
}