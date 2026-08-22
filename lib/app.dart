import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/app_settings_provider.dart';

/// Root widget. Rebuilds when theme/locale/text-scale settings change and hands
/// off navigation to GoRouter.
class PregnancyCompanionApp extends ConsumerWidget {
  const PregnancyCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.materialThemeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        // Apply the user's accessibility text-scale preference, clamped so the
        // layout never breaks.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          // A global offline banner sits above every route (including
          // full-screen pushed ones), so the reassurance is always visible.
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child!),
            ],
          ),
        );
      },
    );
  }
}
