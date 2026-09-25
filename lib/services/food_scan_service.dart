import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitfuel_ai/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;

// Credentials are read from .env instead of being embedded in the app source.
String get kGeminiApiKey => AppConstants.geminiApiKey;
String get kFatSecretClientId => AppConstants.fatSecretClientId;
String get kFatSecretClientSecret => AppConstants.fatSecretClientSecret;

class ScannedFoodItem {
  const ScannedFoodItem({
    required this.name,
    required this.weightG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
    this.imageUrl,
  });

  final String name;
  final double weightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double confidence;
  final String? imageUrl;

  factory ScannedFoodItem.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return ScannedFoodItem(
      name: json['name']?.toString() ?? 'Unknown food',
      weightG: number(json['weight_g']),
      calories: number(json['calories']),
      proteinG: number(json['protein_g']),
      carbsG: number(json['carbs_g']),
      fatG: number(json['fat_g']),
      confidence: number(json['confidence']).clamp(0, 1),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weight_g': weightG,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'confidence': confidence,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class VerifiedFoodItem extends ScannedFoodItem {
  const VerifiedFoodItem({
    required super.name,
    required super.weightG,
    required super.calories,
    required super.proteinG,
    required super.carbsG,
    required super.fatG,
    required super.confidence,
    super.imageUrl,
    this.dbVerified = false,
  });

  final bool dbVerified;

  factory VerifiedFoodItem.fromDbValues(
    ScannedFoodItem geminiItem,
    Map<String, dynamic> dbFood,
  ) {
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    final scale = geminiItem.weightG / 100;
    return VerifiedFoodItem(
      name: dbFood['name']?.toString() ?? geminiItem.name,
      weightG: geminiItem.weightG,
      calories: number(dbFood['calories']) * scale,
      proteinG: number(dbFood['protein']) * scale,
      carbsG: number(dbFood['carbs']) * scale,
      fatG: number(dbFood['fat']) * scale,
      confidence: geminiItem.confidence,
      imageUrl: geminiItem.imageUrl,
      dbVerified: true,
    );
  }

  factory VerifiedFoodItem.fromScanned(ScannedFoodItem item) =>
      VerifiedFoodItem(
        name: item.name,
        weightG: item.weightG,
        calories: item.calories,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
        confidence: item.confidence,
        imageUrl: item.imageUrl,
      );

  @override
  Map<String, dynamic> toJson() =>
      {...super.toJson(), 'db_verified': dbVerified};
}

class FoodScanService {
  static String? _fatSecretToken;
  static DateTime? _fatSecretTokenExpiry;
  String? lastError;

  static const _prompt = '''You are a professional nutritionist AI.
Analyze this food image carefully.
Identify every food item visible.
For each item estimate portion weight using visual cues such as plate size and utensil size.

Return ONLY a valid JSON array with no explanation, no markdown, no code fences.

Format:
[{"name":"grilled chicken breast","weight_g":150,"calories":248,"protein_g":46.2,"carbs_g":0.0,"fat_g":5.4,"confidence":0.92}]

Rules:
- All numeric values must be real numbers never null
- weight_g must be between 10 and 1500
- confidence is 0.0 to 1.0
- If no food visible return exactly []
- Never add any text outside the JSON array''';

  Future<List<ScannedFoodItem>> scanImageFile(File imageFile) async {
    lastError = null;
    if (kGeminiApiKey.isEmpty) {
      lastError =
          'Food scanning is not configured. Add GEMINI_API_KEY to .env.';
      return [];
    }
    try {
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final imageData = base64Encode(await imageFile.readAsBytes());
      final response = await http
          .post(
            Uri.parse(
              '${AppConstants.geminiApiBase}/models/'
              '${AppConstants.geminiModel}:generateContent?key=$kGeminiApiKey',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': _prompt},
                    {
                      'inline_data': {'mime_type': mimeType, 'data': imageData}
                    },
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 1024,
                // Gemini 2.5 supports structured JSON responses. This avoids
                // otherwise valid food detections being wrapped in prose or a
                // Markdown code block.
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        lastError = _apiError(response.body) ??
            'Food scan request failed (HTTP ${response.statusCode}).';
        return [];
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = payload['candidates'] as List?;
      final firstCandidate =
          candidates?.isNotEmpty == true && candidates!.first is Map
              ? Map<String, dynamic>.from(candidates.first as Map)
              : null;
      final content = firstCandidate?['content'];
      final parts = content is Map ? content['parts'] as List? : null;
      final text = parts?.isNotEmpty == true
          ? (parts!.first as Map<String, dynamic>)['text']?.toString()
          : null;
      if (text == null) {
        lastError = 'The AI could not analyze this image. Please try again.';
        return [];
      }
      var cleaned = text
          .replaceAll(RegExp(r'^\s*```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```\s*$', multiLine: true), '')
          .trim();
      // Be tolerant of an occasional introductory sentence despite JSON mode.
      final firstBracket = cleaned.indexOf('[');
      final lastBracket = cleaned.lastIndexOf(']');
      if (firstBracket >= 0 && lastBracket >= firstBracket) {
        cleaned = cleaned.substring(firstBracket, lastBracket + 1);
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) {
        lastError = 'The AI returned an invalid food result. Please try again.';
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => ScannedFoodItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.weightG >= 10 && item.weightG <= 1500)
          .toList();
    } on TimeoutException {
      lastError = 'Gemini took too long to respond. Please try again.';
      return [];
    } on SocketException {
      lastError = 'Could not reach Gemini. Check your internet connection.';
      return [];
    } on FormatException {
      lastError = 'Gemini returned an unreadable result. Please try again.';
      return [];
    } catch (error) {
      // Keep the useful exception visible during setup instead of incorrectly
      // telling the user that an image with visible food has no food in it.
      lastError = 'Food scan failed: $error';
      return [];
    }
  }

  String? _apiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        return (decoded['error'] as Map)['message']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getFatSecretToken() async {
    if (_fatSecretToken != null &&
        _fatSecretTokenExpiry != null &&
        DateTime.now().isBefore(_fatSecretTokenExpiry!)) {
      return _fatSecretToken;
    }
    try {
      final response = await http.post(
        Uri.parse('https://oauth.fatsecret.com/connect/token'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'scope': 'basic',
          'client_id': kFatSecretClientId,
          'client_secret': kFatSecretClientSecret,
        },
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token']?.toString();
      final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
      if (token == null || token.isEmpty) return null;
      _fatSecretToken = token;
      _fatSecretTokenExpiry = DateTime.now().add(
        Duration(seconds: (expiresIn - 60).clamp(1, expiresIn)),
      );
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyWithFatSecret(String foodName) async {
    try {
      final token = await _getFatSecretToken();
      if (token == null) return null;
      final uri = Uri.https('platform.fatsecret.com', '/rest/server.api', {
        'method': 'foods.search',
        'search_expression': foodName,
        'max_results': '1',
        'format': 'json',
      });
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final foods = data['foods'] as Map<String, dynamic>?;
      final rawFood = foods?['food'];
      final food = rawFood is List
          ? (rawFood.isEmpty ? null : rawFood.first as Map<String, dynamic>?)
          : rawFood as Map<String, dynamic>?;
      final description = food?['food_description']?.toString();
      if (food == null || description == null) return null;

      double? value(String pattern) => double.tryParse(
            RegExp(pattern, caseSensitive: false)
                    .firstMatch(description)
                    ?.group(1) ??
                '',
          );
      // FatSecret's search response is generally expressed per serving.  Only
      // descriptions explicitly marked "per 100g" are safe to use as per-100g.
      if (!RegExp(r'per\s*100\s*g', caseSensitive: false)
          .hasMatch(description)) {
        return null;
      }
      final calories = value(r'Calories:\s*([\d.]+)\s*kcal');
      final fat = value(r'Fat:\s*([\d.]+)\s*g');
      final carbs = value(r'Carbs:\s*([\d.]+)\s*g');
      final protein = value(r'Protein:\s*([\d.]+)\s*g');
      if ([calories, fat, carbs, protein].any((item) => item == null))
        return null;
      return {
        'name': food['food_name']?.toString() ?? foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<VerifiedFoodItem>> scanAndVerify(File imageFile) async {
    final results = await scanImageFile(imageFile);
    return Future.wait(results.map((item) async {
      final verified = await verifyWithFatSecret(item.name);
      return verified == null
          ? VerifiedFoodItem.fromScanned(item)
          : VerifiedFoodItem.fromDbValues(item, verified);
    }));
  }
}
