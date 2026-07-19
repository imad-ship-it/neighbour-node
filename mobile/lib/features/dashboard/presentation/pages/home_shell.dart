import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../items/presentation/pages/pending_donations_page.dart';
import '../../../nodes/presentation/pages/map_page.dart';

/// Authenticated home. Plain users get the map full-screen; Node Managers
/// get a bottom nav with a "Manage" tab (donation queue, and the Phase-4
/// dashboard later).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isManager =
        authState is Authenticated && authState.user.isNodeManager;
    if (!isManager) return const MapPage();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          MapPage(),
          PendingDonationsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
