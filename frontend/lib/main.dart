import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'AI Multilingual Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeType),
      home: const DashboardScreen(),
    );
  }
}
