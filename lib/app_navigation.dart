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

  static const List<int> mainIndexes = [0, 1, 3, 4];

  static int? nextIndex(int current) {
    final position = mainIndexes.indexOf(current);
    if (position < 0 || position >= mainIndexes.length - 1) return null;
    return mainIndexes[position + 1];
  }

  static int? previousIndex(int current) {
    final position = mainIndexes.indexOf(current);
    if (position <= 0) return null;
    return mainIndexes[position - 1];
  }

  static void goToIndex(
    BuildContext context,
    int index,
    String userName, {
    int currentIndex = -1,
  }) {
    if (index == currentIndex) return;
    Navigator.of(context).pushReplacement(_route(pageForIndex(index, userName)));
  }

  static PageRouteBuilder _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }
}
