import 'package:flutter/material.dart';
import 'shared/theme/app_theme.dart';
import 'core/config/routes.dart';

class FitFuelApp extends StatelessWidget {
  const FitFuelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FITFUEL AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
