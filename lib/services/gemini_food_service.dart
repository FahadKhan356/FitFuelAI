// lib/services/gemini_food_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../core/constants/app_constants.dart';
import '../models/food_result.dart';

class GeminiFoodService {
  static String get _url {
    final model = AppConstants.geminiModel.isNotEmpty
        ? AppConstants.geminiModel
        : 'gemini-2.5-flash';
    final base = AppConstants.geminiApiBase.isNotEmpty
        ? AppConstants.geminiApiBase
        : 'https://generativelanguage.googleapis.com/v1beta';
    return '$base/models/$model:generateContent?key=${ApiKeys.geminiApiKey}';
  }

  // In-memory cache to prevent redundant API queries
  static final Map<String, FoodResult> _cache = {};

  // ── Build normalized prompt ────────────────────────────────────────
  static String _buildPrompt(String query, String countryCode) => '''
You are a clinical nutrition database API.
User country: $countryCode
User searched for: "$query"

STRICT RULES:
1. Calculate nutrition based on standard cooking in $countryCode.
2. Serving size normalization:
   - Solid foods (biryani, roti, paratha, rice, meat, cheese): baseline = 100 grams
   - Liquids (lassi, soup, tea, juice, milk): baseline = 100 ml
   - Discrete items (1 egg, 1 tablespoon oil, 1 teaspoon sugar): baseline = 1 unit
3. Return ONLY a raw valid JSON object. No markdown. No explanation.

EXACT OUTPUT FORMAT:
{
  "food_name": "Readable food name",
  "cuisine_type": "Pakistani",
  "serving_quantity": 100,
  "serving_unit": "grams",
  "calories": 0.0,
  "protein_g": 0.0,
  "carbs_g": 0.0,
  "fat_g": 0.0,
  "sodium_mg": 0.0,
  "potassium_mg": 0.0,
  "fiber_g": 0.0,
  "sugar_g": 0.0
}

serving_unit must be exactly one of: "grams", "ml", "piece", "tablespoon", "cup"
serving_quantity must be exactly 100 for grams/ml, or 1 for piece/tablespoon/cup
All values must be real numbers, never null or string.
''';

  // ── Fetch from Gemini ─────────────────────────────────────────────
  static Future<FoodResult?> fetch(String query, String countryCode) async {
    final key = query.trim().toLowerCase();
    if (key.length < 2) {
      return null;
    }

    // 1) In-memory cache check
    if (_cache.containsKey(key)) {
      debugPrint('[GeminiFoodService] In-memory cache hit: $key');
      return _cache[key];
    }

    try {
      final apiKey = ApiKeys.geminiApiKey;
      if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
        debugPrint('GeminiFoodService: Missing or placeholder Gemini API key');
        return _fallbackLocal(key, countryCode);
      }

      final body = {
        'contents': [
          {
            'parts': [
              {'text': _buildPrompt(query, countryCode)}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        },
      };

      final res = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 429) {
        debugPrint(
            'GeminiFoodService: Rate limit (HTTP 429) reached. Using local clinical database fallback.');
        final localHit = _fallbackLocal(key, countryCode);
        if (localHit != null) {
          _cache[key] = localHit;
          return localHit;
        }
        return null;
      }

      if (res.statusCode != 200) {
        debugPrint(
            'GeminiFoodService.fetch error HTTP ${res.statusCode}: ${res.body}');
        return _fallbackLocal(key, countryCode);
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
              as String? ??
          '';

      // Strip any accidental markdown fences
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```(json)?\n?'), '');
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final parsed = _parse(json);
      if (parsed != null) {
        _cache[key] = parsed;
        return parsed;
      }
    } on Object catch (e) {
      debugPrint('GeminiFoodService.fetch error: $e');
    }

    final local = _fallbackLocal(key, countryCode);
    if (local != null) {
      _cache[key] = local;
      return local;
    }
    return null;
  }

  static FoodResult? _parse(Map<String, dynamic> j) {
    final calories = (j['calories'] as num? ?? 0).toDouble();
    if (calories == 0) {
      return null;
    }

    return FoodResult(
      foodName: j['food_name'] as String? ?? 'Unknown',
      servingQuantity: (j['serving_quantity'] as num? ?? 100).toDouble(),
      servingUnit: j['serving_unit'] as String? ?? 'grams',
      calories: calories,
      proteinG: (j['protein_g'] as num? ?? 0).toDouble(),
      carbsG: (j['carbs_g'] as num? ?? 0).toDouble(),
      fatG: (j['fat_g'] as num? ?? 0).toDouble(),
      source: 'gemini_ai',
      cuisineType: j['cuisine_type'] as String?,
      sodiumMg: (j['sodium_mg'] as num? ?? 0).toDouble(),
      potassiumMg: (j['potassium_mg'] as num? ?? 0).toDouble(),
      fiberG: (j['fiber_g'] as num? ?? 0).toDouble(),
      sugarG: (j['sugar_g'] as num? ?? 0).toDouble(),
      accuracyWarning: true, // always true for Gemini — show amber badge
    );
  }

  // ── Regional Fallback Data (Active during rate-limits/offline) ──────
  static FoodResult? _fallbackLocal(String key, String countryCode) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final database = <String, FoodResult>{
      'daal chawal': const FoodResult(
        foodName: 'Daal Chawal',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 126,
        proteinG: 5.2,
        carbsG: 22.5,
        fatG: 1.8,
        fiberG: 2.4,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'daal': const FoodResult(
        foodName: 'Daal (Cooked Lentils)',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 116,
        proteinG: 9,
        carbsG: 20,
        fatG: 0.5,
        fiberG: 3.8,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'chawal': const FoodResult(
        foodName: 'Boiled Rice (Chawal)',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 130,
        proteinG: 2.7,
        carbsG: 28.2,
        fatG: 0.3,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'chicken biryani': const FoodResult(
        foodName: 'Chicken Biryani',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 165,
        proteinG: 12.5,
        carbsG: 18,
        fatG: 4.5,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'biryani': const FoodResult(
        foodName: 'Chicken Biryani',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 165,
        proteinG: 12.5,
        carbsG: 18,
        fatG: 4.5,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'chicken karahi': const FoodResult(
        foodName: 'Chicken Karahi',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 185,
        proteinG: 18,
        carbsG: 3.5,
        fatG: 11,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'roti': const FoodResult(
        foodName: 'Roti / Chapati',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 264,
        proteinG: 9.1,
        carbsG: 55,
        fatG: 1.5,
        fiberG: 4,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'chapati': const FoodResult(
        foodName: 'Roti / Chapati',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 264,
        proteinG: 9.1,
        carbsG: 55,
        fatG: 1.5,
        fiberG: 4,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'paratha': const FoodResult(
        foodName: 'Plain Paratha',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 326,
        proteinG: 6.5,
        carbsG: 43,
        fatG: 14.5,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'aloo paratha': const FoodResult(
        foodName: 'Aloo Paratha',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 290,
        proteinG: 6,
        carbsG: 40,
        fatG: 12,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'nihari': const FoodResult(
        foodName: 'Beef Nihari',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 210,
        proteinG: 17.5,
        carbsG: 4,
        fatG: 14,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'haleem': const FoodResult(
        foodName: 'Chicken Haleem',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 160,
        proteinG: 11,
        carbsG: 17,
        fatG: 5.5,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'chai': const FoodResult(
        foodName: 'Doodh Patti Chai',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'ml',
        calories: 75,
        proteinG: 2.5,
        carbsG: 9,
        fatG: 3.2,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
      'naan': const FoodResult(
        foodName: 'Tandoori Naan',
        cuisineType: 'Pakistani',
        servingQuantity: 100,
        servingUnit: 'grams',
        calories: 285,
        proteinG: 8.5,
        carbsG: 52,
        fatG: 4.5,
        source: 'gemini_ai',
        accuracyWarning: true,
      ),
    };

    if (database.containsKey(normalized)) {
      return database[normalized];
    }

    // Partial prefix match in fallback
    for (final entry in database.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    return null;
  }
}
