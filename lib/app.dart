import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/router/app_router.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/widgets/app_background.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class WorldCupPredictorApp extends ConsumerWidget {
  const WorldCupPredictorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Malaz World Cup Arena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
