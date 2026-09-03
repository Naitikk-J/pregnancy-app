import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../push/push_controller.dart';

/// The signed-in app shell with a floating pill navigation bar ("Serene Bloom").
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
    // and proactively ask for notification/alarm permissions up front — on the
    // first launch after install or update — so medicine/water/appointment
    // reminders can actually fire. `ensurePermissionsRequested` is once-per-
    // install, so it won't re-prompt (or re-open the exact-alarm settings
    // screen) on every app open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushControllerProvider).init();
      ref.read(notificationServiceProvider).ensurePermissionsRequested();
    });
  }


  void _onTap(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentIndex = widget.navigationShell.currentIndex;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFFC48B9F).withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavPillItem(
                  icon: Icons.home_rounded,
                  label: l10n.navHome,
                  selected: currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavPillItem(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.navTracker,
                  selected: currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavPillItem(
                  icon: Icons.health_and_safety_rounded,
                  label: 'Care',
                  selected: currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _NavPillItem(
                  icon: Icons.grid_view_rounded,
                  label: l10n.navTools,
                  selected: currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

