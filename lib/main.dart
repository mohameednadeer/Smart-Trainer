import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trainer/theme/app_theme.dart';
import 'package:smart_trainer/router/app_router.dart';
import 'package:smart_trainer/core/providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SmartTrainerApp(),
    ),
  );
}

class SmartTrainerApp extends ConsumerWidget {
  const SmartTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Smart Trainer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
