import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/account_settings_page.dart';
import '../pages/detail_pages.dart';

/// ===============================================================
/// APP SHELL
/// ===============================================================

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.userName,
    required this.body,
    this.activeIndex = -1,
    this.backgroundColor = const Color(0xfff5f8fc),
  });

  final String userName;
  final Widget body;
  final int activeIndex;
  final Color backgroundColor;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeController;

  double _dragOffset = 0;
  bool _isNavigating = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isNavigating) return;

    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return;

    setState(() {
      _dragOffset += details.delta.dx / width;
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isNavigating) return;

    final width = MediaQuery.sizeOf(context).width;
    final velocity = details.primaryVelocity ?? 0;
    final passedThreshold = _dragOffset.abs() > .20;
    final fastSwipe = velocity.abs() > 650;

    int? targetIndex;

    if ((passedThreshold || fastSwipe) && widget.activeIndex >= 0) {
      if (_dragOffset < 0 && widget.activeIndex < 4) {
        targetIndex = widget.activeIndex + 1;
      } else if (_dragOffset > 0 && widget.activeIndex > 0) {
        targetIndex = widget.activeIndex - 1;
      }
    }

    if (targetIndex == null) {
      final start = _dragOffset;
      final animation = Tween<double>(
        begin: start,
        end: 0,
      ).animate(
        CurvedAnimation(
          parent: _swipeController,
          curve: Curves.easeOutCubic,
        ),
      );

      _swipeController
        ..reset()
        ..duration = const Duration(milliseconds: 220);

      void listener() {
        if (mounted) {
          setState(() => _dragOffset = animation.value);
        }
      }

      animation.addListener(listener);
      await _swipeController.forward();
      animation.removeListener(listener);
      return;
    }

    _isNavigating = true;

    final direction = _dragOffset < 0 ? -1.0 : 1.0;
    final animation = Tween<double>(
      begin: _dragOffset,
      end: direction,
    ).animate(
      CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _swipeController
      ..reset()
      ..duration = const Duration(milliseconds: 180);

    void listener() {
      if (mounted) {
        setState(() => _dragOffset = animation.value);
      }
    }

    animation.addListener(listener);
    await _swipeController.forward();
    animation.removeListener(listener);

    if (!mounted) return;

    _pushPageForIndex(targetIndex);
  }

  void _pushPageForIndex(int index) {
    Widget? page;

    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 1:
        page = InOutPage(userName: widget.userName);
        break;
      case 3:
        page = RekapanTransaksiPage(userName: widget.userName);
        break;
      case 4:
        page = LinenBelumKembaliPage(userName: widget.userName);
        break;
      default:
        _isNavigating = false;
        _dragOffset = 0;
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page!,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final now = DateTime.now();
    final last = _lastBackPress;

    if (last == null ||
        now.difference(last) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tekan tombol kembali sekali lagi untuk keluar.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 88),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Transform.translate(
                  offset: Offset(
                    _dragOffset * MediaQuery.sizeOf(context).width,
                    0,
                  ),
                  child: widget.body,
                ),
              ),
            ),

            // Navbar remains completely fixed while the page content moves.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(
                userName: widget.userName,
                activeIndex: widget.activeIndex,
              ),
            ),
          ],
        ),
      ),
    );
      ),
    );
  }
}

/// ===============================================================
/// DASHBOARD HEADER
/// ===============================================================

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
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
          bottom: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          /// Decorative circles
          Positioned(
            right: -45,
            top: -60,
            child: _BlurCircle(
              size: 160,
              color: Colors.white.withValues(alpha: .10),
            ),
          ),

          Positioned(
            right: 50,
            bottom: -90,
            child: _BlurCircle(
              size: 190,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),

          Positioned(
            left: -80,
            top: 80,
            child: _BlurCircle(
              size: 140,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              20,
              28,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .20),
                          ),
                        ),
                        child: const Text(
                          'SUPERADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Halo, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Rumah Sakit Anugerah Global Sehat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withValues(alpha: .75),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Jl. Surabaya • Indonesia',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .78),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                _HeaderActionButton(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountSettingsPage(
                          userName: userName,
                        ),
                      ),
                    );
                  },
                  icon: Icons.group_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// HEADER ACTION
/// ===============================================================

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.onTap,
    required this.icon,
  });

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: .30),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// METRIC CARD
/// ===============================================================

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.metrics,
    required this.userName,
  });

  final List<dynamic> metrics;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff183b56).withValues(alpha: .08),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: metrics.asMap().entries.map(
            (entry) {
              return MetricTile(
                metric: entry.value as Map<String, dynamic>,
                index: entry.key,
                onTap: () {
                  if (entry.key == 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LinenReadyPage(userName: userName),
                      ),
                    );
                  } else if (entry.key == 1) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LinenLaundryPage(userName: userName)));
                  } else if (entry.key == 2) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LinenRuanganPage(userName: userName)));
                  } else {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Menu ini akan dihubungkan ke data detail.',
                          ),
                        ),
                      );
                  }
                },
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

/// ===============================================================
/// METRIC TILE
/// ===============================================================

class MetricTile extends StatefulWidget {
  const MetricTile({
    super.key,
    required this.metric,
    required this.onTap,
    this.index = 0,
  });

  final Map<String, dynamic> metric;
  final VoidCallback onTap;
  final int index;

  @override
  State<MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<MetricTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;

    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xfff3f8fc)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _MetricIcon(
                index: widget.index,
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${metric['value']}',
                    style: const TextStyle(
                      color: Color(0xff172b4d),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric['unit'] as String,
                    style: const TextStyle(
                      color: Color(0xff9aa8b5),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    metric['title'] as String,
                    style: const TextStyle(
                      color: Color(0xff52616f),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        metric['action'] as String,
                        style: const TextStyle(
                          color: Color(0xff159cf1),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xff159cf1),
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// METRIC ICON
/// ===============================================================

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.inventory_2_rounded,
      Icons.local_laundry_service_rounded,
      Icons.check_circle_rounded,
      Icons.warning_amber_rounded,
    ];

    final colors = [
      const Color(0xff159cf1),
      const Color(0xff5cc9bd),
      const Color(0xff36b37e),
      const Color(0xffffa940),
    ];

    final i = index % icons.length;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors[i].withValues(alpha: .10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icons[i],
        color: colors[i],
        size: 22,
      ),
    );
  }
}

/// ===============================================================
/// GENERIC DASHBOARD CARD
/// ===============================================================

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      color: Colors.transparent,
      child: child,
    );
  }
}
/// ===============================================================
/// SECTION TITLE
/// ===============================================================

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xff159cf1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff34495e),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// CATEGORY ITEM
/// ===============================================================

class CategoryItem extends StatefulWidget {
  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Map<String, dynamic> category;
  final VoidCallback onTap;

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.category['label'] as String;

    final icon = label.contains('Rusak')
        ? Icons.warning_amber_rounded
        : Icons.search_off_rounded;

    final color = Color(widget.category['color']);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .10),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      const Color(0xff00a8bd),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff4c5c68),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// TRANSACTION ITEM
/// ===============================================================

class TransactionItem extends StatefulWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final label = transaction['label'] as String;

    final icon = label.contains('Keluar')
        ? Icons.north_east_rounded
        : label.contains('Masuk')
            ? Icons.south_west_rounded
            : Icons.assignment_rounded;

    final color = Color(transaction['color']);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .10),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff4c5c68),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// DETAIL HEADER
/// ===============================================================

class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    required this.userName,
  });

  final String title;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        8,
        12,
        18,
        18,
      ),
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
          bottom: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(15),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .20),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
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

/// ===============================================================
/// DETAIL TABLE
/// ===============================================================

class DetailTable extends StatelessWidget {
  const DetailTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                headingRowHeight: 46,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 54,
                horizontalMargin: 18,
                columnSpacing: 28,
                headingRowColor:
                    WidgetStateProperty.all(
                  const Color(0xff1261dc),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xff465564),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                dividerThickness: .4,
                columns: columns
                    .map(
                      (column) => DataColumn(
                        label: Text(column),
                      ),
                    )
                    .toList(),
                rows: rows.map((row) {
                  return DataRow(
                    cells: (row as List<dynamic>)
                        .map(
                          (value) => DataCell(
                            Text('$value'),
                          ),
                        )
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// ROOM TABLE
/// ===============================================================

class RoomTable extends StatelessWidget {
  const RoomTable({
    super.key,
    required this.rooms,
  });

  final List<dynamic> rooms;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              14,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff1261dc),
                  Color(0xff159cf1),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Keluar Masuk Linen & Tirai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(145),
                1: FixedColumnWidth(100),
                2: FixedColumnWidth(100),
                3: FixedColumnWidth(90),
              },
              children: [
                _roomRow(
                  [
                    'Nama Ruangan',
                    'Linen Masuk',
                    'Linen Keluar',
                    'Selisih',
                  ],
                  true,
                ),
                ...rooms.asMap().entries.map(
                  (entry) {
                    final room =
                        entry.value as Map<String, dynamic>;

                    return _roomRow(
                      [
                        room['name'] as String,
                        '${room['in']}',
                        '${room['out']}',
                        '${room['difference']}',
                      ],
                      false,
                      entry.key.isEven,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _roomRow(
    List<String> values,
    bool header, [
    bool shaded = false,
  ]) {
    return TableRow(
      decoration: BoxDecoration(
        color: header
            ? const Color(0xfff1f6fb)
            : shaded
                ? const Color(0xfffafcff)
                : Colors.white,
      ),
      children: values.map(
        (value) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 13,
            ),
            child: Text(
              value,
              textAlign: value == values.first
                  ? TextAlign.left
                  : TextAlign.center,
              style: TextStyle(
                color: header
                    ? const Color(0xff52616f)
                    : const Color(0xff5f6f7c),
                fontSize: 9,
                fontWeight: header
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

/// ===============================================================
/// BOTTOM NAVIGATION
/// ===============================================================

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.userName,
    this.activeIndex = -1,
  });

  final String userName;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xff116ea5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: .24),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0b4770).withValues(alpha: .28),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                active: activeIndex == 0,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Keluar Masuk',
                active: activeIndex == 1,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => InOutPage(userName: userName),
                    ),
                  );
                },
              ),
            ),
            _QRNavButton(
              active: activeIndex == 2,
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Endpoint QR Check belum tersedia di API yang diberikan.',
                      ),
                    ),
                  );
              },
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Rekap',
                active: activeIndex == 3,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RekapanTransaksiPage(userName: userName),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.assignment_late_rounded,
                label: 'Belum Kembali',
                active: activeIndex == 4,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LinenBelumKembaliPage(userName: userName),
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

/// ===============================================================
/// QR NAV BUTTON
/// ===============================================================

class _QRNavButton extends StatefulWidget {
  const _QRNavButton({
    required this.onTap,
    required this.active,
  });

  final VoidCallback onTap;
  final bool active;

  @override
  State<_QRNavButton> createState() => _QRNavButtonState();
}

class _QRNavButtonState extends State<_QRNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
      lowerBound: .97,
      upperBound: 1.0,
    )..repeat(
        reverse: true,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(
            bottom: 7,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.active
                  ? const [
                      Color(0xffffd54f),
                      Color(0xffff9800),
                    ]
                  : const [
                      Color(0xffffc107),
                      Color(0xffff9800),
                    ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .9),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffffa000)
                    .withValues(alpha: .40),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// NAV ITEM
/// ===============================================================

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .88 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Positioned.fill(
                  child: Hero(
                    tag: 'bottom-nav-active-indicator',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: widget.active ? 38 : 30,
                    height: widget.active ? 28 : 24,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.active
                          ? Colors.white
                          : Colors.white.withValues(alpha: .68),
                      size: widget.active ? 20 : 19,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.active
                          ? Colors.white
                          : Colors.white.withValues(alpha: .68),
                      fontSize: 7,
                      fontWeight: widget.active
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// BLUR DECORATION
/// ===============================================================

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}