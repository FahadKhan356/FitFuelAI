import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/constants/app_constants.dart';

/// Production-ready Google Gemini Flash service using the official
/// `google_generative_ai` SDK. Supports text queries and multimodality (vision).
///
/// Designed modularly: reads key from compile-time `--dart-define=GEMINI_API_KEY`
/// or runtime `.env`. Zero code modifications are required when switching
/// between Google AI Studio free keys and Google Cloud production paid billing.
class GeminiFlashService {
  GeminiFlashService({
    String? apiKey,
    String? modelName,
  })  : _apiKey = (apiKey ?? _resolveApiKey()).trim(),
        _modelName = modelName ?? _resolveModelName();

  String _apiKey;
  final String _modelName;

  static String _resolveApiKey() {
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (compileTimeKey.isNotEmpty) return compileTimeKey;
    return AppConstants.geminiApiKey;
  }

  static String _resolveModelName() {
    const compileTimeModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: '');
    if (compileTimeModel.isNotEmpty) return compileTimeModel;
    // Defaults to gemini-1.5-flash as specified
    return AppConstants.envValue('GEMINI_MODEL', 'gemini-1.5-flash');
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel _getModel({String? systemInstruction}) {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: systemInstruction != null
          ? Content.system(systemInstruction)
          : null,
      generationConfig: GenerationConfig(
        temperature: 0.6,
        topP: 0.95,
        maxOutputTokens: AppConstants.aiCoachMaxOutputTokens,
      ),
    );
  }

  /// Sends a text prompt to Gemini Flash.
  Future<String> generateText({
    required String prompt,
    String? systemInstruction,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'GEMINI_API_KEY is not configured. Provide it via .env or --dart-define=GEMINI_API_KEY.',
      );
    }

    try {
      final model = _getModel(systemInstruction: systemInstruction);
      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw StateError('Gemini Flash returned an empty response.');
      }
      return text;
    } catch (e) {
      debugPrint('GeminiFlashService: Generation failed: $e');
      rethrow;
    }
  }

  /// Multimodal vision query (e.g. food scan analysis).
  Future<String> generateWithVision({
    required String prompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? systemInstruction,
  }) async {
    if (!isConfigured) {
      throw StateError('GEMINI_API_KEY is not configured.');
    }

    try {
      final model = _getModel(systemInstruction: systemInstruction);
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ]),
      ]);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw StateError('Gemini Flash vision returned an empty response.');
      }
      return text;
    } catch (e) {
      debugPrint('GeminiFlashService: Vision generation failed: $e');
      rethrow;
    }
  }

  /// Update key dynamically if user supplies custom key or on account change.
  void updateApiKey(String newKey) {
    _apiKey = newKey.trim();
  }
}
