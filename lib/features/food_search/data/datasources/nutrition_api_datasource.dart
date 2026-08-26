import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/nutrition_food.dart';

/// Remote food data source backed by the real, free nutrition APIs:
/// - USDA FoodData Central (search + nutrition when API key provided)
/// - OpenFoodFacts (search + packaged food fallback, no key required)
///
/// Every method already maps results to a normalized `[NutritionFood]` so the
/// UI/model layer never has to understand the raw API shapes.
class NutritionApiDataSource {
  static const int _timeout = 15;

  /// Searches a food query, preferring USDA when an API key is configured and
  /// falling back to OpenFoodFacts otherwise.
  Future<List<NutritionFood>> searchFoods(String query) async {
    if (query.trim().isEmpty) return const [];

    if (AppConstants.usdaApiKey.isNotEmpty) {
      try {
        final results = await _searchUsda(query);
        if (results.isNotEmpty) return results;
      } catch (_) {
        // Fall through to OpenFoodFacts on USDA failure.
      }
    }
    return _searchOpenFoodFacts(query);
  }

  /// Looks up a single packaged product by barcode via OpenFoodFacts.
  Future<NutritionFood?> getProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    final uri = Uri.parse(
        '${AppConstants.openFoodFactsProductBase}/$barcode.json');
    try {
      final res =
          await http.get(uri).timeout(const Duration(seconds: _timeout));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      return _fromOpenFoodFactsProduct(barcode, product);
    } catch (_) {
      return null;
    }
  }

  // ── USDA FoodData Central ────────────────────────────────────
  Future<List<NutritionFood>> _searchUsda(String query) async {
    final uri = Uri.parse('${AppConstants.usdaApiBase}/foods/search').replace(
      queryParameters: {
        'api_key': AppConstants.usdaApiKey,
        'query': query,
        'pageSize': '25',
        'dataType': 'Foundation,SR Legacy,Survey (FNDDS)',
      },
    );

    final res = await http.get(uri).timeout(const Duration(seconds: _timeout));
    if (res.statusCode != 200) {
      throw Exception('USDA search failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = (json['foods'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final food in foods.take(25)) {
      final nutrients = _usdaNutrientMap(food['foodNutrients']);
      final id = (food['fdcId'] ?? '').toString();
      results.add(NutritionFood(
        source: 'USDA',
        externalId: id,
        name: (food['description'] as String?)?.isNotEmpty == true
            ? food['description'] as String
            : query,
        brand: food['brandOwner'] as String?,
        energyKcal: nutrients[208] ?? 0,
        protein: nutrients[203] ?? 0,
        carbs: nutrients[205] ?? 0,
        fat: nutrients[204] ?? 0,
        fiber: nutrients[291] ?? 0,
        sugar: nutrients[269] ?? 0,
        sodiumMg: nutrients[307] ?? 0,
        potassiumMg: nutrients[306] ?? 0,
        calciumMg: nutrients[301] ?? 0,
        ironMg: nutrients[303] ?? 0,
        vitaminCMg: nutrients[401] ?? 0,
      ));
    }
    return results;
  }

  /// Maps USDA FDC nutrient arrays (id -> value per 100g) to a simple map.
  Map<int, double> _usdaNutrientMap(dynamic raw) {
    final map = <int, double>{};
    final list = (raw as List? ?? const []);
    for (final item in list) {
      final typed = item as Map<String, dynamic>;
      final id = (typed['nutrient']?['id'] ?? typed['nutrientId']) as int?;
      final amount = (typed['amount'] as num?)?.toDouble();
      if (id != null && amount != null) {
        map[id] = amount;
      }
    }
    return map;
  }

  // ── OpenFoodFacts ───────────────────────────────────────────
  Future<List<NutritionFood>> _searchOpenFoodFacts(String query) async {
    final uri =
        Uri.parse(AppConstants.openFoodFactsSearchBase).replace(queryParameters: {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '25',
    });

    final res = await http.get(uri, headers: {
      'User-Agent': 'FitFuelAI/1.0 (nutrition tracking)',
    }).timeout(const Duration(seconds: _timeout));
    if (res.statusCode != 200) {
      throw Exception('OpenFoodFacts search failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (json['products'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final product in products.take(25)) {
      final barcode = (product['_id'] ?? '').toString();
      results.add(_fromOpenFoodFactsProduct(barcode, product));
    }
    return results;
  }

  NutritionFood _fromOpenFoodFactsProduct(
      String barcode, Map<String, dynamic> product) {
    final nutrients = product['nutriments'] as Map<String, dynamic>? ?? const {};
    return NutritionFood(
      source: 'OpenFoodFacts',
      externalId: barcode,
      name: (product['product_name'] as String?)?.isNotEmpty == true
          ? product['product_name'] as String
          : 'Packaged Food',
      brand: product['brands'] as String?,
      energyKcal: _num(nutrients['energy-kcal_100g']) ?? 0,
      protein: _num(nutrients['proteins_100g']) ?? 0,
      carbs: _num(nutrients['carbohydrates_100g']) ?? 0,
      fat: _num(nutrients['fat_100g']) ?? 0,
      fiber: _num(nutrients['fiber_100g']) ?? 0,
      sugar: _num(nutrients['sugars_100g']) ?? 0,
      sodiumMg: _num(nutrients['sodium_100g']) ?? 0,
    );
  }

  static double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}