import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/detail_pages.dart';

class AppNavigation {
  const AppNavigation._();

  static Widget pageForIndex(int index, String userName) {
    switch (index) {
      case 0:
        return DashboardPage(userName: userName, embedded: true);
      case 1:
        return InOutPage(userName: userName, embedded: true);
      case 3:
        return RekapanTransaksiPage(userName: userName, embedded: true);
      case 4:
        return LinenBelumKembaliPage(userName: userName, embedded: true);
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
    final bool fromRight = _isMovingFromRight(currentIndex, index);

    Navigator.of(context).pushReplacement(
      _route(
        pageForIndex(index, userName),
        fromRight: fromRight,
      ),
    );
  }

  static bool _isMovingFromRight(
    int currentIndex,
    int newIndex,
  ) {
    final currentPosition = mainIndexes.indexOf(currentIndex);
    final newPosition = mainIndexes.indexOf(newIndex);

    if (currentPosition < 0 || newPosition < 0) {
      return true;
    }

    return newPosition > currentPosition;
  }

  static PageRouteBuilder _route(
    Widget page, {
    required bool fromRight,
  }) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final Offset begin = fromRight
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0);

        const Offset end = Offset.zero;

        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: end,
          ).animate(curve),
          child: child,
        );
      },
    );
  }
}
