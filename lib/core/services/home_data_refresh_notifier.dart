import 'package:flutter/foundation.dart';

/// Simple app-wide signal used to tell the home dashboard to reload its data
/// after something changed elsewhere (e.g. a meal was logged in the meal
/// tracker). Home listens to this and re-fetches from the DB so the consumed
/// calories / macros / water stay in sync across screens.
class HomeDataRefreshNotifier extends ChangeNotifier {
  HomeDataRefreshNotifier._();
  static final HomeDataRefreshNotifier instance = HomeDataRefreshNotifier._();

  /// Notify listeners that dashboard data may have changed.
  void refresh() => notifyListeners();
}