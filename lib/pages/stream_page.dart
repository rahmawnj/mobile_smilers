import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_service.dart';

class StreamPage extends StatefulWidget {
  const StreamPage({super.key});

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  StreamResponse? _data;
  String? _error;
  bool _loading = true;
  String _liveClock = '';
  AppInfo? _appInfo;
  String _appLogoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _updateClock();
    _listenLoop();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

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
                      const Text(
                        'STREAM',
                        style: TextStyle(
                          color: Color(0xff173A58),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Real-time Linen Monitoring',
                        style: TextStyle(
                          color: Color(0xff8291A0),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF5F8FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Color(0xff118D9A),
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                (data?.waktu.trim().isNotEmpty ?? false) ? data!.waktu : (_liveClock.isEmpty ? 'Menghubungkan...' : _liveClock),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xff526575),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              value: data == null ? '—' : data.total.toString(),
                              label: 'JUMLAH LINEN',
                              icon: Icons.layers_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              value: data == null
                                  ? '—'
                                  : _formatWeight(data.berat),
                              label: 'BERAT LINEN',
                              icon: Icons.monitor_weight_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xffb05a5a),
                            fontSize: 9,
                          ),
                        ),
                      ],
                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff118D9A),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Back to Homepage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1197A2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xfff7fafc),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xff159cf1),
            size: 20,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff173A58),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff7b8b99),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}
