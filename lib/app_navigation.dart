import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/detail_pages.dart';

class AppNavigation {
  const AppNavigation._();

  static Widget pageForIndex(int index, String userName) {
    switch (index) {
      case 0:
        return DashboardPage(userName: userName);
      case 1:
        return InOutPage(userName: userName);
      case 3:
        return RekapanTransaksiPage(userName: userName);
      case 4:
        return LinenBelumKembaliPage(userName: userName);
      default:
        return DashboardPage(userName: userName);
    }
  }

  static void goToIndex(
    BuildContext context,
    int index,
    String userName, {
    int currentIndex = -1,
  }) {
    if (index == currentIndex) return;

    Navigator.of(context).pushReplacement(
      _route(
        pageForIndex(index, userName),
        fromRight: index > currentIndex,
      ),
    );
  }

  static PageRouteBuilder _route(
    Widget page, {
    required bool fromRight,
  }) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(fromRight ? 1 : -1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}
