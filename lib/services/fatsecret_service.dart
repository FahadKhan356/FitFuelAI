// lib/services/fatsecret_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/food_result.dart';

class FatSecretService {
  static const _tokenUrl = 'https://oauth.fatsecret.com/connect/token';
  static const _apiUrl = 'https://platform.fatsecret.com/rest/server.api';

  // Token cache
  static String? _token;
  static DateTime? _tokenExpiry;

  // ── Get OAuth2 token (cached) ──────────────────────────────────────
  static Future<String?> _getToken() async {
    if (_token != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _token;
    }
    try {
      final clientId = ApiKeys.fatSecretClientId;
      final clientSecret = ApiKeys.fatSecretClientSecret;
      if (clientId.isEmpty || clientSecret.isEmpty || clientId.contains('YOUR_')) {
        debugPrint('FatSecretService: Missing or placeholder API keys');
        return null;
      }

      final res = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'scope': 'basic',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['access_token'] as String?;
        final expires = (data['expires_in'] as num?)?.toInt() ?? 86400;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expires - 120));
        return _token;
      } else {
        debugPrint('FatSecretService._getToken failed: ${res.statusCode} ${res.body}');
      }
    } on Object catch (e) {
      debugPrint('FatSecretService._getToken error: $e');
    }
    return null;
  }

  // ── Search foods ──────────────────────────────────────────────────
  static Future<List<FoodResult>> search(String query) async {
    final token = await _getToken();
    if (token == null) {
      return [];
    }

    try {
      final uri = Uri.parse(_apiUrl).replace(queryParameters: {
        'method': 'foods.search',
        'search_expression': query,
        'max_results': '10',
        'format': 'json',
      });

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = data['foods']?['food'];
      if (foods == null) {
        return [];
      }

      final list = foods is List ? foods : [foods];
      return list
          .map((f) => _parse(f as Map<String, dynamic>))
          .whereType<FoodResult>()
          .toList();
    } on Object catch (e) {
      debugPrint('FatSecretService.search error: $e');
      return [];
    }
  }

  // ── Parse FatSecret food_description string ───────────────────────
  // FatSecret returns: "Per 100g - Calories: 165kcal | Fat: 3.57g | Carbs: 0g | Protein: 31g"
  static FoodResult? _parse(Map<String, dynamic> f) {
    final desc = f['food_description'] as String? ?? '';

    double extract(RegExp pattern) {
      final match = pattern.firstMatch(desc);
      return match != null ? double.tryParse(match.group(1) ?? '0') ?? 0 : 0;
    }

    final calories = extract(RegExp(r'Calories:\s*([\d.]+)'));
    if (calories == 0) {
      return null; // skip items with no nutrition data
    }

    return FoodResult(
      foodName: f['food_name'] as String? ?? 'Unknown',
      servingQuantity: 100,
      servingUnit: 'grams',
      calories: calories,
      proteinG: extract(RegExp(r'Protein:\s*([\d.]+)')),
      carbsG: extract(RegExp(r'Carbs:\s*([\d.]+)')),
      fatG: extract(RegExp(r'Fat:\s*([\d.]+)')),
      source: 'fatsecret_api',
      fiberG: extract(RegExp(r'Fiber:\s*([\d.]+)')),
      sodiumMg: extract(RegExp(r'Sodium:\s*([\d.]+)')),
      accuracyWarning: false,
    );
  }
}
