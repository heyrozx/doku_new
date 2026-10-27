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
        // The floating navigation bar overlays the content; pages add
        // MediaQuery bottom padding so nothing stays hidden behind it.
        extendBody: true,
        body: IndexedStack(index: _index, children: pages),
        floatingActionButton: _index < 2
            ? FloatingActionButton.extended(
                onPressed: () => TransactionFormScreen.open(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : null,
        bottomNavigationBar: _FloatingNavBar(
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
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);
    final surface = scheme.surface;
    return DecoratedBox(
      // Fade the content that scrolls underneath into the page background.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [surface.withValues(alpha: 0), surface],
          stops: const [0, 0.55],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: scheme.brightness == Brightness.light ? 0.12 : 0.45,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: NavigationBar(
                height: 64,
                // Icons only; labels stay available as tooltips and for
                // screen readers.
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                backgroundColor: scheme.surfaceContainerLowest,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
