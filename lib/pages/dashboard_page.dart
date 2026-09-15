import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../widgets/shared_widgets.dart';
import 'detail_pages.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final dashboard = dashboardData;
    final categories = dashboard['categories'] as List<dynamic>;
    final transactions = dashboard['transactions'] as List<dynamic>;

    return AppShell(
      userName: userName,
      activeIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(children: [
              DashboardHeader(userName: userName),
              Transform.translate(offset: const Offset(0, -50), child: MetricCard(metrics: dashboard['metrics'] as List<dynamic>, userName: userName)),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    DashboardCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionTitle(title: 'Data Linen & Tirai'),
                        const SizedBox(height: 14),
                        Row(children: categories.asMap().entries.map((entry) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: CategoryItem(category: entry.value as Map<String, dynamic>, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryDetailPage(type: entry.key, userName: userName))))))).toList()),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    DashboardCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionTitle(title: 'Transaksi Linen & Tirai'),
                        const SizedBox(height: 14),
                        Row(children: transactions.asMap().entries.map((entry) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: TransactionItem(key: ValueKey('transaction-${entry.key}'), transaction: entry.value as Map<String, dynamic>, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => entry.key == 2 ? RequestPage(userName: userName) : TransactionDetailPage(type: entry.key, userName: userName))))))).toList()),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    RoomTable(rooms: dashboard['rooms'] as List<dynamic>),
                  ]),
                ),
              ),
            ]),
        ),
    );
  }
}
