import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/routes.dart';
import 'core/di/service_locator.dart';
import 'shared/theme/app_theme.dart';

class FitFuelApp extends StatelessWidget {
  const FitFuelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
      providers: blocProviders,
      child: MaterialApp.router(
        title: 'FITFUEL AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: goRouter,
      ),
    );
}
