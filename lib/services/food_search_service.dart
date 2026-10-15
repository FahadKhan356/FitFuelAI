import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_result.dart';
import 'fatsecret_service.dart';
import 'gemini_food_service.dart';
import 'usda_service.dart';

class FoodSearchService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Normalize search key ───────────────────────────────────────────
  static String _key(String q) =>
      q.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  // ── MAIN METHOD — UI calls only this ──────────────────────────────
  static Future<List<FoodResult>> search(
    String query, {
    String countryCode = 'GLOBAL',
  }) async {
    final key = _key(query);
    if (key.isEmpty) return [];

    List<FoodResult> results = [];

    // ══ TIER 1: USDA Foundation Foods ════════════════════════════════
    // Best for generic foods: chicken, rice, apple, egg, milk, etc.
    // Free: 1000 calls/hour | Verified USDA laboratory data
    debugPrint('[Search] TIER 1 — USDA: $key');
    results = await UsdaService.search(query);
    if (results.isNotEmpty) {
      debugPrint('[Search] USDA hit ✓ (${results.length} results)');
      unawaited(_cacheToSupabase(results.first, key, countryCode));
      return results;
    }

    // ══ TIER 2: Supabase Cache ════════════════════════════════════════
    // Our local DB — Open Food Facts bulk data + previously cached items
    // Fastest tier once data is imported
    debugPrint('[Search] TIER 2 — Supabase: $key');
    results = await _searchSupabase(key);
    if (results.isNotEmpty) {
      debugPrint('[Search] Supabase hit ✓ (${results.length} results)');
      return results;
    }

    // ══ TIER 3: FatSecret API ═════════════════════════════════════════
    // 1.9M branded + restaurant foods | Free: 5000 calls/day
    debugPrint('[Search] TIER 3 — FatSecret: $key');
    results = await FatSecretService.search(query);
    if (results.isNotEmpty) {
      debugPrint('[Search] FatSecret hit ✓ (${results.length} results)');
      unawaited(_cacheToSupabase(results.first, key, countryCode));
      return results;
    }

    // ══ TIER 4: Gemini AI (LAST RESORT) ══════════════════════════════
    // Only for regional cuisine not in any database
    // e.g. "Nihari", "Haleem", "Aloo Palak"
    // accuracyWarning = true → amber badge in UI
    debugPrint('[Search] TIER 4 — Gemini fallback: $key ($countryCode)');
    final gemini = await GeminiFoodService.fetch(query, countryCode);
    if (gemini != null) {
      debugPrint('[Search] Gemini hit ✓ (AI estimated)');
      unawaited(_cacheToSupabase(gemini, key, countryCode));
      return [gemini];
    }

    debugPrint('[Search] No results found for: $key');
    return [];
  }

  // ── Supabase smart search ──────────────────────────────────────────
  static Future<List<FoodResult>> _searchSupabase(String key) async {
    try {
      // 1. Try exact key match first (fastest)
      var rows = await _db
          .from('food_items')
          .select()
          .eq('search_key', key)
          .limit(5);

      if ((rows as List).isNotEmpty) {
        return rows
            .map((r) => FoodResult.fromSupabase(r as Map<String, dynamic>))
            .toList();
      }

      // 2. Full-text search (uses GIN index — fast even with 200k+ rows)
      try {
        rows = await _db
            .from('food_items')
            .select()
            .textSearch('search_vector', key, config: 'english')
            .limit(10);

        if ((rows as List).isNotEmpty) {
          return rows
              .map((r) => FoodResult.fromSupabase(r as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // If search_vector column is not yet migrated, fall back to ilike
      }

      // 3. Fallback: partial name match (ilike)
      rows = await _db
          .from('food_items')
          .select()
          .ilike('food_name', '%$key%')
          .limit(10);

      return (rows as List)
          .map((r) => FoodResult.fromSupabase(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FoodSearchService] _searchSupabase error: $e');
      return [];
    }
  }

  // ── Save to Supabase cache (non-blocking) ──────────────────────────
  static Future<void> _cacheToSupabase(
    FoodResult result,
    String searchKey,
    String countryCode,
  ) async {
    try {
      // Check if already exists to avoid duplicates
      final existing = await _db
          .from('food_items')
          .select('id')
          .eq('search_key', searchKey)
          .limit(1);

      if ((existing as List).isNotEmpty) return; // already cached

      await _db.from('food_items').insert(
            result.toSupabaseMap(searchKey, countryCode),
          );
    } catch (e) {
      debugPrint('[FoodSearchService] _cacheToSupabase error: $e');
      // Never crash — cache write failure is non-critical
    }
  }
}
