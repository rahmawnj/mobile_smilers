import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/keluar_masuk_page.dart';
import 'pages/rekap_page.dart';
import 'pages/belum_kembali_page.dart';
import 'widgets/shared_widgets.dart';

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
        return DashboardPage(userName: userName, embedded: true);
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
    final shell = context.findAncestorStateOfType<AppShellState>();
    shell?.switchTo(index);
  }
}
