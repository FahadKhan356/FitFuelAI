import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/nutrition_food.dart';

/// Remote food data source backed by three real, free nutrition APIs:
/// - USDA FoodData Central  -> complete macros + micronutrients
///   (KEY FIX: we now pass `dataType=Foundation,SR Legacy` AND the explicit
///   `nutrients=` id list so raw foods return full nutrition, not the sparse
///   Branded-only rows).
/// - OpenFoodFacts -> packaged foods + real product **images**, no key needed.
/// - CalorieNinjas -> natural-language queries ("2 eggs and toast",
///   "100g chicken"), active only when a key is configured.
///
/// Every method maps results to a normalized `[NutritionFood]` (per 100 g) so
/// the UI/model layer never has to understand the raw API shapes.
class NutritionApiDataSource {
  static const int _timeout = 15;

  /// In-memory cache of recent searches (query -> results) to avoid redundant
  /// network calls and give instant results when a query is repeated.
  final Map<String, List<NutritionFood>> _cache = {};
  static const int _cacheMax = 30;

  // USDA nutrient IDs requested so results are complete.
  // 203=Protein 204=Total fat 205=Carbs 208=Energy kcal 269=Sugar 291=Fiber
  // 307=Sodium 301=Calcium 303=Iron 306=Potassium 401=VitC 606=Sat. fat
  static const String _usdaNutrientFilter =
      '203,204,205,208,269,291,307,301,306,303,401,606';

  // ---- Main public APIs ------------------------------------------------

  /// Searches a food query using the triple-API pipeline (USDA -> Open Food
  /// Facts -> CalorieNinjas) and returns de-duplicated, normalized results.
  /// Results are cached by query.
  Future<List<NutritionFood>> searchFoods(String query) async {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return const [];

    // Cache hit -> return immediately.
    final cached = _cache[key];
    if (cached != null) return cached;

    // Run all configured providers concurrently and merge.
    final futures = <Future<List<NutritionFood>>>[];
    futures.add(_searchUsda(query));
    futures.add(_searchOpenFoodFacts(query));
    if (AppConstants.calorieNinjasApiKey.isNotEmpty) {
      futures.add(_searchCalorieNinjas(query));
    }

    final settled = await Future.wait(futures);
    final merged = <NutritionFood>[];
    for (final list in settled) {
      merged.addAll(list);
    }
    final results = _dedupe(merged);

    // Store in cache (cap size to avoid unbounded growth).
    if (results.isNotEmpty) {
      _cache[key] = results;
      if (_cache.length > _cacheMax) {
        _cache.remove(_cache.keys.first);
      }
    }
    return results;
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
// ---- 1. USDA FoodData Central (Foundation + SR Legacy) -----------

  Future<List<NutritionFood>> _searchUsda(String query) async {
    // KEY FIX: constrain to Foundation/SR Legacy so we get academic-grade,
    // complete nutrition instead of sparse Branded rows, and pass the
    // `nutrients` filter so every macro + micro we need is returned.
    final uri = Uri.parse('${AppConstants.usdaApiBase}/foods/search').replace(
      queryParameters: {
        'api_key': AppConstants.usdaApiKey,
        'query': query,
        'pageSize': '25',
        'dataType': 'Foundation,SR Legacy',
        'nutrients': _usdaNutrientFilter,
      },
    );

    final res = await http.get(uri).timeout(const Duration(seconds: _timeout));
    if (res.statusCode != 200) {
      return const [];
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = (json['foods'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final food in foods) {
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
        saturatedFatG: nutrients[606] ?? 0,
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
// ---- 2. OpenFoodFacts (packaged foods + real images) ------------

  Future<List<NutritionFood>> _searchOpenFoodFacts(String query) async {
    final uri =
        Uri.parse(AppConstants.openFoodFactsSearchBase).replace(queryParameters: {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '25',
      // Ask the API to fill the English product name & language tag so results
      // are relevant for an English user instead of surfacing arbitrary
      // foreign-language products (e.g. "Mayonnaise Classique ...").
      'lang': 'en',
      'fields':
          'product_name,product_name_en,lang,brands,image_url,nutriments',
    });

    final res = await http.get(uri, headers: {
      'User-Agent': 'FitFuelAI/1.0 (nutrition tracking)',
    }).timeout(const Duration(seconds: _timeout));
    if (res.statusCode != 200) {
      return const [];
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (json['products'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final product in products.take(25)) {
      final barcode = (product['_id'] ?? '').toString();
      final parsed = _fromOpenFoodFactsProduct(barcode, product);
      // Skip products that carry no nutrition data at all.
      if (parsed.energyKcal > 0 || parsed.protein > 0 || parsed.carbs > 0) {
        results.add(parsed);
      }
    }
    // Rank the most English-relevant matches first so an English query doesn't
    // lead with a random foreign-branded food.
    results.sort((a, b) {
      final aScore = _languageScore(a);
      final bScore = _languageScore(b);
      return bScore.compareTo(aScore);
    });
    return results;
  }

  /// Small heuristic: prefer products whose stored name looks English over ones
  /// that are clearly a foreign language (heavy diacritics) or non-Latin.
  int _languageScore(NutritionFood f) {
    final nonLatin = RegExp(r'[\u0600-\u06FF\u0400-\u04FF\u0900-\u097F'
        r'\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF\u0370-\u03FF]');
    final diacritics = RegExp(r'[àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ]');
    var score = 0;
    if (nonLatin.hasMatch(f.name)) {
      score -= 10; // Hindi/Chinese/Arabic/Cyrillic/Greek names are never English.
    }
    if (diacritics.hasMatch(f.name)) {
      score -= 3; // accented words are usually French/Spanish/Portuguese etc.
    }
    return score;
  }

  NutritionFood _fromOpenFoodFactsProduct(
      String barcode, Map<String, dynamic> product) {
    final nutrients = product['nutriments'] as Map<String, dynamic>? ?? const {};
    return NutritionFood(
      source: 'OpenFoodFacts',
      externalId: barcode,
      // Prefer the English product name when the API provided one, else fall
      // back to the default name.
      name: (product['product_name_en'] as String?)?.isNotEmpty == true
          ? product['product_name_en'] as String
          : (product['product_name'] as String?)?.isNotEmpty == true
              ? product['product_name'] as String
              : 'Packaged Food',
      brand: product['brands'] as String?,
      imageUrl: product['image_url'] as String?,
      energyKcal: _num(nutrients['energy-kcal_100g']) ?? 0,
      protein: _num(nutrients['proteins_100g']) ?? 0,
      carbs: _num(nutrients['carbohydrates_100g']) ?? 0,
      fat: _num(nutrients['fat_100g']) ?? 0,
      saturatedFatG: _num(nutrients['saturated-fat_100g']) ?? 0,
      fiber: _num(nutrients['fiber_100g']) ?? 0,
      sugar: _num(nutrients['sugars_100g']) ?? 0,
      sodiumMg: _num(nutrients['sodium_100g']) ?? 0,
      potassiumMg: _num(nutrients['potassium_100g']) ?? 0,
      calciumMg: _num(nutrients['calcium_100g']) ?? 0,
      ironMg: _num(nutrients['iron_100g']) ?? 0,
      vitaminCMg: _num(nutrients['vitamin-c_100g']) ?? 0,
    );
  }
// ---- 3. CalorieNinjas (natural language, per-100g normalized) ---

  Future<List<NutritionFood>> _searchCalorieNinjas(String query) async {
    final uri = Uri.parse(AppConstants.calorieNinjasApiBase).replace(
      queryParameters: {'query': query},
    );
    final res = await http.get(uri, headers: {
      'X-Api-Key': AppConstants.calorieNinjasApiKey,
    }).timeout(const Duration(seconds: _timeout));
    if (res.statusCode != 200) return const [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final item in items) {
      final serving = (item['serving_size_g'] as num?)?.toDouble() ?? 100;
      final factor = serving > 0 ? 100 / serving : 1.0;
      final name = (item['name'] as String?)?.isNotEmpty == true
          ? item['name'] as String
          : query;
      results.add(NutritionFood(
        source: 'CalorieNinjas',
        externalId: name,
        name: name,
        energyKcal: _scale(item['calories'], factor),
        protein: _scale(item['protein_g'], factor),
        carbs: _scale(item['carbohydrates_total_g'], factor),
        fat: _scale(item['fat_total_g'], factor),
        saturatedFatG: _scale(item['fat_saturated_g'], factor),
        fiber: _scale(item['fiber_g'], factor),
        sugar: _scale(item['sugar_g'], factor),
        sodiumMg: _scale(item['sodium_mg'], factor),
        potassiumMg: _scale(item['potassium_mg'], factor),
      ));
    }
    return results;
  }

  double _scale(dynamic value, double factor) {
    if (value == null) return 0;
    final n = value is num ? value.toDouble() : double.tryParse(value.toString());
    return n == null ? 0 : n * factor;
  }

  // ---- Helpers -------------------------------------------------------

  /// Merges results, dropping entries with no nutrition at all and
  /// de-duplicating by (source + externalId) and by normalized name.
  List<NutritionFood> _dedupe(List<NutritionFood> input) {
    final byId = <String, NutritionFood>{};
    final byName = <String, NutritionFood>{};
    for (final f in input) {
      if (f.energyKcal <= 0 && f.protein <= 0 && f.carbs <= 0 && f.fat <= 0) {
        continue;
      }
      if (f.externalId.isNotEmpty) {
        final idKey = '${f.source}|${f.externalId}';
        final existing = byId[idKey];
        if (existing == null || _score(f) > _score(existing)) byId[idKey] = f;
      } else {
        final nameKey = '${f.source}|${f.name.toLowerCase()}';
        final existing = byName[nameKey];
        if (existing == null || _score(f) > _score(existing)) {
          byName[nameKey] = f;
        }
      }
    }
    return <NutritionFood>[...byId.values, ...byName.values];
  }

  /// Favours entries with more populated fields (a product image adds weight).
  int _score(NutritionFood f) {
    var s = 0;
    if (f.energyKcal > 0) s++;
    if (f.protein > 0) s++;
    if (f.carbs > 0) s++;
    if (f.fat > 0) s++;
    if (f.fiber > 0) s++;
    if (f.sugar > 0) s++;
    if (f.sodiumMg > 0) s++;
    if (f.imageUrl != null && f.imageUrl!.isNotEmpty) s += 2;
    return s;
  }

  static double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}