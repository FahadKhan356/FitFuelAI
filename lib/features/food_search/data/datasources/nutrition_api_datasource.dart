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

    // A failure from one provider must not hide valid results from the others.
    final settled = await Future.wait(
      futures.map((future) async {
        try {
          return await future;
        } catch (_) {
          return const <NutritionFood>[];
        }
      }),
    );
    final merged = <NutritionFood>[];
    for (final list in settled) {
      merged.addAll(list);
    }
    var results = _dedupe(merged);
    // Rank by how well the result matches what the user actually typed, so an
    // English query like "eggs" leads with "Egg, whole, raw" instead of some
    // fully-populated branded product that merely contains egg as an ingredient.
    results.sort((a, b) =>
        _relevanceScore(b, query).compareTo(_relevanceScore(a, query)));

    // Never show an unrelated product just because it came from a provider
    // that has a source bonus. This matters most for Open Food Facts, whose
    // broad product search can otherwise return weak matches.
    results = results.where((f) => _matchesQuery(f, query)).toList();

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
    final uri =
        Uri.parse('${AppConstants.openFoodFactsProductBase}/$barcode.json');
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
    final foods =
        (json['foods'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final food in foods) {
      final nutrients = _usdaNutrientMap(food['foodNutrients']);
      final id = (food['fdcId'] ?? '').toString();
      if (id.isEmpty) continue;
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
      final nutrient = typed['nutrient'];
      // USDA search responses expose the food nutrient database id (1003),
      // while the API nutrient filter uses the nutrient number (203).
      // Detailed responses may instead expose a nested nutrient.id.
      final idValue = nutrient is Map
          ? (nutrient['number'] ?? nutrient['id'])
          : (typed['nutrientNumber'] ?? typed['nutrientId']);
      final id = idValue is num ? idValue.toInt() : int.tryParse('$idValue');
      // Search results use `value`; detailed food responses use `amount`.
      final rawAmount = typed['amount'] ?? typed['value'];
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse('$rawAmount');
      if (id != null && amount != null) {
        map[id] = amount;
      }
    }
    return map;
  }
// ---- 2. OpenFoodFacts (packaged foods + real images) ------------

  Future<List<NutritionFood>> _searchOpenFoodFacts(String query) async {
    final queryParameters = {
      'search_terms': query,
      'search_simple': '1',
      'page_size': '50',
      'sort_by': 'unique_scans_n',
      'lang': 'en',
      'fields': [
        'code',
        'product_name',
        'product_name_en',
        'generic_name',
        'generic_name_en',
        'lang',
        'brands',
        'image_url',
        'image_front_small_url',
        'nutriments',
        'serving_size',
        'quantity',
      ].join(','),
    };

    Map<String, dynamic>? json;
    for (final baseUrl in [
      AppConstants.openFoodFactsSearchBase,
      AppConstants.openFoodFactsFallbackSearchBase,
    ]) {
      try {
        final res = await http.get(
          Uri.parse(baseUrl).replace(queryParameters: queryParameters),
          headers: {'User-Agent': 'FitFuelAI/1.0 (nutrition tracking)'},
        ).timeout(const Duration(seconds: _timeout));
        if (res.statusCode != 200) continue;
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['products'] is List) {
          json = decoded;
          break;
        }
      } catch (_) {
        // Try the global host if the regional host is unavailable.
      }
    }
    if (json == null) return const [];

    final products = (json['products'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final results = <NutritionFood>[];
    for (final product in products.take(50)) {
      final barcode = (product['code'] ?? product['_id'] ?? '').toString();
      final parsed = _fromOpenFoodFactsProduct(barcode, product);
      // Skip products that carry no nutrition data at all.
      if (parsed.energyKcal > 0 || parsed.protein > 0 || parsed.carbs > 0) {
        results.add(parsed);
      }
    }
    // Rank popular, complete English products first. Popularity is supplied by
    // Open Food Facts; the global ranking below also considers query fit.
    results.sort((a, b) {
      final aScore = _languageScore(a) + _score(a);
      final bScore = _languageScore(b) + _score(b);
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
      score -=
          10; // Hindi/Chinese/Arabic/Cyrillic/Greek names are never English.
    }
    if (diacritics.hasMatch(f.name)) {
      score -= 3; // accented words are usually French/Spanish/Portuguese etc.
    }
    return score;
  }

  NutritionFood _fromOpenFoodFactsProduct(
      String barcode, Map<String, dynamic> product) {
    final nutrients =
        product['nutriments'] as Map<String, dynamic>? ?? const {};
    return NutritionFood(
      source: 'OpenFoodFacts',
      externalId: barcode,
      // Prefer the English product/generic name so branded products remain
      // useful for queries such as "greek yogurt" or "protein bar".
      name: _firstNonEmpty([
            product['product_name_en'],
            product['product_name'],
            product['generic_name_en'],
            product['generic_name'],
          ]) ??
          'Packaged Food',
      brand: product['brands'] as String?,
      imageUrl: _firstNonEmpty([
        product['image_front_small_url'],
        product['image_url'],
      ]),
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
    final items =
        (data['items'] as List? ?? const []).whereType<Map<String, dynamic>>();
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
    final n =
        value is num ? value.toDouble() : double.tryParse(value.toString());
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

  /// Ranks a food against the search query. The name matching the query is the
  /// dominant signal; source & nutrition are tie-breakers. Whole academic foods
  /// (USDA) beat branded packaged items when relevance is otherwise equal.
  int _relevanceScore(NutritionFood f, String query) {
    final q = _normalize(query);
    final name = _normalize(f.name);

    var score = 0;
    if (name == q) {
      score += 40; // exact match wins outright.
    } else if (name.startsWith(q)) {
      score += 25; // "egg..." for "egg".
    } else if (name.contains(q)) {
      score += 18; // name contains the full query.
    } else {
      // Token match: every query word present in the name adds weight.
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2);
      for (final t in tokens) {
        if (name.contains(t)) score += 10;
      }
    }

    // Whole-food sources are more relevant for plain ingredient queries.
    if (f.source == 'USDA') score += 3;
    if (f.source == 'CalorieNinjas') score += 1;

    // Nutrition completeness as a mild final tie-breaker.
    score += _score(f) ~/ 10;

    return score;
  }

  bool _matchesQuery(NutritionFood food, String query) {
    final queryTokens = _normalize(query)
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1);
    final nameTokens = _normalize(food.name).split(RegExp(r'\s+'));
    // Match complete words or word prefixes. Substring matching made "ric"
    // match the middle of "abricot", which produced unrelated French foods.
    return queryTokens.every(
      (queryToken) => nameTokens.any((nameToken) =>
          nameToken == queryToken || nameToken.startsWith(queryToken)),
    );
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
