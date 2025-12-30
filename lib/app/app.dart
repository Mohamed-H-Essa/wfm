import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themes/intrazero_2026_theme.dart';
import 'routes/app_routes.dart';

class IntraZeroEmployeeApp extends ConsumerWidget {
  const IntraZeroEmployeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'IntraZero Employee',
      debugShowCheckedModeBanner: false,
      theme: IntraZero2026Theme.lightTheme,
      darkTheme: IntraZero2026Theme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

