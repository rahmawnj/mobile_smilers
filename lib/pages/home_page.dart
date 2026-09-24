import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';
import 'detail_pages.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.userName, this.embedded = false});

  final String userName;
  final bool embedded;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;
  List<LinenCategory> _linen = const [];
  int _laundryCount = 0;
  int _roomCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLinen();
  }

  Future<void> _loadLinen() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.getLinen(perPage: 10),
        ApiService.instance.getLinenLaundry(perPage: 1000),
        ApiService.instance.getLinenRuangan(perPage: 1000),
      ]);
      if (!mounted) return;

      final linenResponse = results[0] as LinenListResponse<LinenCategory>;
      final laundryResponse =
          results[1] as LinenListResponse<LinenLaundryItem>;
      final roomResponse =
          results[2] as LinenListResponse<LinenRuanganItem>;

      setState(() {
        _linen = linenResponse.data;
        _laundryCount = laundryResponse.meta.total;
        _roomCount = roomResponse.data.fold<int>(
          0,
          (sum, item) => sum + item.linenDiRuangan,
        );
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat mengambil data Linen & Tirai dari server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = _linen.fold<int>(0, (sum, item) => sum + item.jumlahStok);
    final totalMissing =
        _linen.fold<int>(0, (sum, item) => sum + item.jumlahHilang);

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      embedded: widget.embedded,
      body: RefreshIndicator(
        onRefresh: _loadLinen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              DashboardHeader(userName: widget.userName),
              Transform.translate(
                offset: const Offset(0, -50),
                child: MetricCard(
                  metrics: [
                    {
                      'value': _loading ? '...' : _laundryCount.toString(),
                      'unit': 'Linen',
                      'title': 'Linen & Tirai Ready',
                      'action': 'Lihat Data',
                    },
                    {
                      'value': _loading ? '...' : totalStock.toString(),
                      'unit': 'Linen',
                      'title': 'Linen & Tirai di Laundry',
                      'action': 'Lihat Data',
                    },
                    {
                      'value': _loading ? '...' : _roomCount.toString(),
                      'unit': 'Linen',
                      'title': 'Linen & Tirai di Ruangan',
                      'action': 'Lihat Data',
                    },
                  ],
                  userName: widget.userName,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(title: 'Data Linen & Tirai'),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _DashboardDataMenu(
                                    icon: Icons.broken_image_rounded,
                                    title: 'Linen & Tirai Rusak',
                                    subtitle: 'Data linen dan tirai yang rusak',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LinenRusakPage(
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DashboardDataMenu(
                                    icon: Icons.report_problem_rounded,
                                    title: 'Linen & Tirai Hilang',
                                    subtitle: 'Data linen dan tirai yang hilang',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LinenHilangPage(
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(title: 'Transaksi Linen & Tirai'),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _DashboardDataMenu(
                                    icon: Icons.output_rounded,
                                    title: 'Data Linen & Tirai Keluar',
                                    subtitle: 'Data linen dan tirai yang keluar',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LinenKeluarPage(
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DashboardDataMenu(
                                    icon: Icons.input_rounded,
                                    title: 'Data Linen & Tirai Masuk',
                                    subtitle: 'Data linen dan tirai yang masuk',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LinenMasukPage(
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DashboardDataMenu(
                                    icon: Icons.assignment_rounded,
                                    title: 'Permintaan Ruangan',
                                    subtitle: 'Permintaan linen dari ruangan',
                                    onTap: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PermintaanLinenPage(userName: widget.userName)));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardDataMenu extends StatelessWidget {
  const _DashboardDataMenu({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xff159cf1).withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: const Color(0xff159cf1), size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff34495e),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinenCategoryCard extends StatelessWidget {
  const _LinenCategoryCard({required this.item, required this.onTap});

  final LinenCategory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subCategory = item.subKategoriLinen.trim().isEmpty
        ? 'Tidak ada sub kategori'
        : item.subKategoriLinen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xff159cf1).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xff159cf1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaKategoriLinen,
                      style: const TextStyle(
                        color: Color(0xff34495e),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subCategory,
                      style: const TextStyle(
                        color: Color(0xff8b99a5),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.jumlahStok.toString(),
                    style: const TextStyle(
                      color: Color(0xff159cf1),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'READY',
                    style: TextStyle(
                      color: Color(0xff8b99a5),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff9aa8b5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34, color: Color(0xffef6c6c)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
