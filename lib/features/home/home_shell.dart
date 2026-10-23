import 'package:doku/features/dashboard/dashboard_page.dart';
import 'package:doku/features/more/more_page.dart';
import 'package:doku/features/reports/reports_page.dart';
import 'package:doku/features/transactions/transaction_form_screen.dart';
import 'package:doku/features/transactions/transactions_page.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onSeeAllTransactions: () => _select(1),
        onOpenReports: () => _select(2),
      ),
      const TransactionsPage(),
      const ReportsPage(),
      const MorePage(),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        floatingActionButton: _index < 2
            ? FloatingActionButton.extended(
                onPressed: () => TransactionFormScreen.open(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Catat'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined_rounded),
              selectedIcon: Icon(Icons.insert_chart_rounded),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Lainnya',
            ),
          ],
        ),
      ),
    );
  }
}
