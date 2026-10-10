// lib/services/food_search_service.dart
// This is the ONLY file the rest of the app calls.
// UI never calls FatSecret or Gemini directly.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_result.dart';
import 'fatsecret_service.dart';
import 'gemini_food_service.dart';

class FoodSearchService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Normalize search key (prevents duplicate cache entries) ────────
  static String _normalizeKey(String input) =>
      input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  // ── MAIN SEARCH — call this from UI ───────────────────────────────
  // query: what user typed
  // countryCode: 'PK', 'IN', 'US', 'GB', etc.
  static Future<List<FoodResult>> search(
    String query, {
    String countryCode = 'PK',
  }) async {
    final key = _normalizeKey(query);
    if (key.isEmpty) {
      return [];
    }

    // ── TIER 1: Supabase cache ──────────────────────────────────────
    final cached = await _searchSupabase(key, countryCode);
    if (cached.isNotEmpty) {
      debugPrint('[FoodSearch] Cache hit: $key');
      return cached;
    }

    // ── TIER 2: FatSecret (all countries — generic foods) ──────────
    final fatSecretResults = await FatSecretService.search(query);
    if (fatSecretResults.isNotEmpty) {
      debugPrint('[FoodSearch] FatSecret hit: $key');
      // Cache top result in Supabase (check duplicate first)
      await _saveToSupabase(fatSecretResults.first, key, countryCode);
      return fatSecretResults;
    }

    // ── TIER 3: Gemini (regional/cuisine fallback) ─────────────────
    debugPrint('[FoodSearch] Gemini fallback: $key ($countryCode)');
    final geminiResult = await GeminiFoodService.fetch(query, countryCode);
    if (geminiResult != null) {
      await _saveToSupabase(geminiResult, key, countryCode);
      return [geminiResult];
    }

    // Nothing found anywhere
    return [];
  }

  // ── Supabase cache lookup ──────────────────────────────────────────
  static Future<List<FoodResult>> _searchSupabase(
    String key,
    String countryCode,
  ) async {
    try {
      // Search by exact key first, then partial match
      final rows = await _db
          .from('food_items')
          .select()
          .or('search_key.eq.$key,food_name.ilike.%$key%')
          .limit(10);

      return (rows as List)
          .map((r) => FoodResult.fromSupabase(r as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      debugPrint('FoodSearchService._searchSupabase error: $e');
      return [];
    }
  }

  // ── Save to Supabase cache ─────────────────────────────────────────
  static Future<void> _saveToSupabase(
    FoodResult result,
    String searchKey,
    String countryCode,
  ) async {
    try {
      final safeCountryCode =
          countryCode.length > 5 ? countryCode.substring(0, 5) : countryCode;
      // Prevent duplicate row for same search_key and country_code
      final existing = await _db
          .from('food_items')
          .select('id')
          .eq('search_key', searchKey)
          .eq('country_code', safeCountryCode)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        return;
      }

      await _db.from('food_items').insert(
            result.toSupabaseMap(searchKey, safeCountryCode),
          );
    } on Object catch (e) {
      // Don't crash if cache write fails — just log
      debugPrint('FoodSearchService._saveToSupabase error: $e');
    }
  }
}
