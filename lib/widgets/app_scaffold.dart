import 'package:flutter/material.dart';
import 'package:invoice_flow/screens/dashboard_screen.dart';
import 'package:invoice_flow/screens/invoice_list_screen.dart';
import 'package:invoice_flow/screens/history_screen.dart';
import 'package:invoice_flow/screens/settings_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InvoiceListScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return DefaultTabController(
      length: _screens.length,
      child: Scaffold(
        body: Row(
          children: [
            if (isDesktop)
              NavigationRail(
                extended: MediaQuery.of(context).size.width > 1200,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Invoices'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: Text('History'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: !isDesktop
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Invoices',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
