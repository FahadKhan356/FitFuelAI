import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitfuel_ai/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;

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

  final String name;
  final double weightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double confidence;
  final String? imageUrl;

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

  final bool dbVerified;

  @override
  Map<String, dynamic> toJson() =>
      {...super.toJson(), 'db_verified': dbVerified};
}

class FoodScanService {
  static String? _fatSecretToken;
  static DateTime? _fatSecretTokenExpiry;
  String? lastError;

  static const _prompt = '''
You are a professional nutritionist AI.
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

  static const _foodResponseSchema = {
    'type': 'ARRAY',
    'items': {
      'type': 'OBJECT',
      'properties': {
        'name': {'type': 'STRING'},
        'weight_g': {'type': 'NUMBER'},
        'calories': {'type': 'NUMBER'},
        'protein_g': {'type': 'NUMBER'},
        'carbs_g': {'type': 'NUMBER'},
        'fat_g': {'type': 'NUMBER'},
        'confidence': {'type': 'NUMBER'},
      },
      'required': [
        'name',
        'weight_g',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'confidence',
      ],
    },
  };

  Future<List<ScannedFoodItem>> scanImageFile(File imageFile) async {
    lastError = null;
    if (kGeminiApiKey.isEmpty) {
      lastError =
          'Food scanning is not configured. Add GEMINI_API_KEY to .env.';
      return [];
    }
    try {
      // Gallery images are not guaranteed to be JPEGs (iPhones often keep
      // HEIC/PNG files).  Sending the original bytes with a guessed MIME type
      // makes Gemini treat an otherwise good photo as corrupt.  Normalising
      // decoded images gives Gemini a consistent, supported JPEG payload.
      final upload = await _prepareImageForGemini(imageFile);
      try {
        return _parseFoodItems(await _requestScan(upload, structured: true));
      } on FormatException {
        // Models can occasionally return prose or a truncated structured
        // response. Retry once without the schema; the prompt still demands
        // JSON and the tolerant parser below handles wrapper objects too.
        try {
          return _parseFoodItems(
            await _requestScan(upload, structured: false),
          );
        } on FormatException {
          lastError =
              'The AI could not read the result. Please retake the photo with the food clearly visible.';
          return [];
        }
      }
    } on TimeoutException {
      lastError = 'Gemini took too long to respond. Please try again.';
      return [];
    } on SocketException {
      lastError = 'Could not reach Gemini. Check your internet connection.';
      return [];
    } on _GeminiRequestException catch (error) {
      lastError = error.message;
      return [];
    } on FormatException {
      lastError =
          'This image format is not supported. Choose a JPG or PNG photo.';
      return [];
    } catch (error) {
      // Keep the useful exception visible during setup instead of incorrectly
      // telling the user that an image with visible food has no food in it.
      lastError = 'Food scan failed: $error';
      return [];
    }
  }

  Future<_GeminiImage> _prepareImageForGemini(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = image.decodeImage(bytes);
    // `package:image` cannot decode HEIC, but Gemini accepts HEIC/HEIF.
    // Preserve those bytes with their real MIME type instead of falsely
    // declaring them JPEGs (the former source of the unreadable result).
    if (decoded == null) {
      final mimeType = _heifMimeType(bytes);
      if (mimeType == null) {
        throw const FormatException('unsupported image format');
      }
      return _GeminiImage(base64Encode(bytes), mimeType);
    }
    final normalized = decoded.width > 1600 || decoded.height > 1600
        ? image.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1600 : null,
            height: decoded.height > decoded.width ? 1600 : null,
          )
        : decoded;
    return _GeminiImage(
      base64Encode(image.encodeJpg(normalized, quality: 88)),
      'image/jpeg',
    );
  }

  String? _heifMimeType(List<int> bytes) {
    if (bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
      return null;
    }
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (const {'heic', 'heix', 'hevc', 'hevx'}.contains(brand)) {
      return 'image/heic';
    }
    if (const {'mif1', 'msf1'}.contains(brand)) return 'image/heif';
    return null;
  }

  Future<String> _requestScan(
    _GeminiImage upload, {
    required bool structured,
  }) async {
    final generationConfig = <String, dynamic>{
      'temperature': 0.1,
      'maxOutputTokens': 2048,
      'responseMimeType': 'application/json',
    };
    if (structured) generationConfig['responseSchema'] = _foodResponseSchema;

    final response = await http
        .post(
          Uri.parse('${AppConstants.geminiApiBase}/models/'
              '${AppConstants.geminiModel}:generateContent?key=$kGeminiApiKey'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': _prompt},
                  {
                    'inline_data': {
                      'mime_type': upload.mimeType,
                      'data': upload.base64Data,
                    },
                  },
                ],
              },
            ],
            'generationConfig': generationConfig,
          }),
        )
        .timeout(const Duration(seconds: 40));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _GeminiRequestException(_apiError(response.body) ??
          'Food scan request failed (HTTP ${response.statusCode}).');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map) throw const FormatException('invalid Gemini payload');
    final candidates = payload['candidates'];
    if (candidates is! List) throw const FormatException('no Gemini candidate');
    for (final candidate in candidates.whereType<Map>()) {
      final content = candidate['content'];
      final parts = content is Map ? content['parts'] : null;
      if (parts is! List) continue;
      final text = parts
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();
      if (text.isNotEmpty) return text;
    }
    throw const FormatException('no text in Gemini response');
  }

  List<ScannedFoodItem> _parseFoodItems(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'^\s*```(?:json)?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```\s*$', multiLine: true), '')
        .replaceAll(RegExp(r',\s*([}\]])'), r'$1')
        .trim();
    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException {
      final first = cleaned.indexOf('[');
      final last = cleaned.lastIndexOf(']');
      if (first < 0 || last < first) rethrow;
      decoded = jsonDecode(cleaned.substring(first, last + 1));
    }
    // Accept common valid wrapper shapes as a compatibility fallback.
    if (decoded is Map) {
      decoded = decoded['foods'] ?? decoded['items'] ?? decoded['results'];
    }
    if (decoded is! List) {
      throw const FormatException('food result is not a list');
    }
    return decoded
        .whereType<Map>()
        .map((item) => ScannedFoodItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) =>
            item.name.trim().isNotEmpty &&
            item.weightG >= 10 &&
            item.weightG <= 1500)
        .toList();
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
      if ([calories, fat, carbs, protein].any((item) => item == null)) {
        return null;
      }
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

class _GeminiImage {
  const _GeminiImage(this.base64Data, this.mimeType);

  final String base64Data;
  final String mimeType;
}

class _GeminiRequestException implements Exception {
  const _GeminiRequestException(this.message);

  final String message;
}
