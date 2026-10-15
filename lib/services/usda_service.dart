import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/food_result.dart';

class UsdaService {
  static String get _apiKey => AppConstants.envValue(
        'USDA_API_KEY',
        'bjw4xgN7S5EqQHqycCbyyf1Co2vNhbg549Y1fqeb',
      );

  static String get _baseUrl => AppConstants.envValue(
        'USDA_API_BASE',
        'https://api.nal.usda.gov/fdc/v1',
      );

  /// Search USDA Foundation + SR Legacy foods (complete verified nutrition data)
  static Future<List<FoodResult>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/foods/search').replace(
        queryParameters: {
          'query': cleanQuery,
          'dataType': 'Foundation,SR Legacy', // CRITICAL: not Branded
          'pageSize': '10',
          'api_key': _apiKey,
          // Request specific nutrient IDs:
          // 208=calories 203=protein 204=fat 205=carbs
          // 291=fiber 269=sugar 307=sodium 306=potassium
          'nutrients': '208,203,204,205,291,269,307,306,1008,1003,1004,1005,1079,2000,1093,1092',
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('[UsdaService] HTTP ${res.statusCode}: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = data['foods'] as List<dynamic>? ?? [];

      return foods
          .map((f) => _parse(f as Map<String, dynamic>))
          .whereType<FoodResult>()
          .toList();
    } catch (e) {
      debugPrint('[UsdaService] search error: $e');
      return [];
    }
  }

  static FoodResult? _parse(Map<String, dynamic> f) {
    double nut(List<dynamic> nuts, List<int> ids, [List<String>? nameMatches]) {
      try {
        for (final n in nuts) {
          final nid = n['nutrientId'] as int?;
          if (nid != null && ids.contains(nid)) {
            final val = (n['value'] as num? ?? 0).toDouble();
            if (val > 0) return val;
          }
        }
        if (nameMatches != null) {
          for (final n in nuts) {
            final name = (n['nutrientName'] as String? ?? '').toLowerCase();
            for (final match in nameMatches) {
              if (name.contains(match)) {
                return (n['value'] as num? ?? 0).toDouble();
              }
            }
          }
        }
      } catch (_) {}
      return 0.0;
    }

    final nutrients = f['foodNutrients'] as List<dynamic>? ?? [];

    // Calories: 208, 1008, or name containing "energy"
    var calories = nut(nutrients, [208, 1008], ['energy']);
    // Fallback: calculate from macros if calories is 0
    final protein = nut(nutrients, [203, 1003], ['protein']);
    final carbs = nut(nutrients, [205, 1005], ['carbohydrate']);
    final fat = nut(nutrients, [204, 1004], ['total lipid', 'fat']);

    if (calories == 0 && (protein > 0 || carbs > 0 || fat > 0)) {
      calories = (protein * 4) + (carbs * 4) + (fat * 9);
    }

    if (calories == 0) return null;

    final fiber = nut(nutrients, [291, 1079], ['fiber']);
    final sugar = nut(nutrients, [269, 2000, 1063], ['sugar']);
    final sodium = nut(nutrients, [307, 1093], ['sodium']);
    final potassium = nut(nutrients, [306, 1092], ['potassium']);

    final description = f['description'] as String? ?? 'Unknown';

    return FoodResult(
      foodName: _cleanFoodName(description),
      servingQuantity: 100,
      servingUnit: 'grams',
      calories: double.parse(calories.toStringAsFixed(1)),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      fiberG: double.parse(fiber.toStringAsFixed(1)),
      sugarG: double.parse(sugar.toStringAsFixed(1)),
      sodiumMg: double.parse(sodium.toStringAsFixed(1)),
      potassiumMg: double.parse(potassium.toStringAsFixed(1)),
      source: 'usda_api',
      accuracyWarning: false,
    );
  }

  /// Cleans technical USDA descriptions (e.g. "Chicken, breast, meat only, raw" -> "Chicken Breast")
  static String _cleanFoodName(String raw) {
    if (!raw.contains(',')) return raw.trim();
    final parts = raw.split(',').map((p) => p.trim()).toList();
    if (parts.length >= 2) {
      // Capitalize first 2 relevant segments
      return '${parts[0]} ${parts[1]}';
    }
    return raw.trim();
  }
}
