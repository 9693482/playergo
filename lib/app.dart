import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/connectivity_banner.dart';
import 'generated/app_localizations.dart';

class PlayerGoApp extends ConsumerWidget {
  const PlayerGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PlayerGo',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const _RefreshIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        _RefreshIntent: _RefreshAction(),
      },
      builder: (context, child) => ConnectivityBanner(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _RefreshAction extends Action<_RefreshIntent> {
  @override
  Object? invoke(covariant _RefreshIntent intent) {
    // El refresh se maneja en cada screen individualmente
    return null;
  }
}
