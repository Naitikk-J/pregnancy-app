import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../push/push_controller.dart';

/// The signed-in app shell: a bottom [NavigationBar] hosting the Home, Tracker,
/// Tools and Profile branches via GoRouter's [StatefulNavigationShell] (state is
/// preserved per tab). Community & AI tabs are added in their phases.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Register for push once we're in the signed-in shell (guarded internally),
    // and proactively ask for notification permission so medicine/water/
    // appointment reminders can actually fire (many users never open the
    // Medicines screen where it was previously requested).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushControllerProvider).init();
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  void _onTap(int index) {
    // initialLocation: re-tapping the active tab returns to its root.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navTracker,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l10n.navTools,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
