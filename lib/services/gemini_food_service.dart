// lib/services/gemini_food_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/food_result.dart';

class GeminiFoodService {
  static String get _url =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash:generateContent?key=${ApiKeys.geminiApiKey}';

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
    try {
      final apiKey = ApiKeys.geminiApiKey;
      if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
        debugPrint('GeminiFoodService: Missing or placeholder Gemini API key');
        return null;
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
          'maxOutputTokens': 512,
        },
      };

      final res = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        debugPrint('GeminiFoodService.fetch error HTTP ${res.statusCode}: ${res.body}');
        return null;
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
      return _parse(json);
    } on Object catch (e) {
      debugPrint('GeminiFoodService.fetch error: $e');
      return null;
    }
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
}
