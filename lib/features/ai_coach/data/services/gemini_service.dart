import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';

/// Raised whenever Gemini cannot produce an answer (missing key, network
/// failure, quota, safety block...). Callers fall back to
/// `CoachFallbackResponder` instead of surfacing a raw exception.
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}

/// Minimal REST client for Gemini's `generateContent` endpoint.
///
/// Deliberately dependency-light (only `package:http`, already used by the
/// nutrition data sources) so it works on every platform without codegen.
class GeminiService {
  final http.Client _client;
  final Duration _timeout;
  final bool _isConfigured;

  GeminiService({
    http.Client? client,
    Duration? timeout,
    String? apiKey,
    String? model,
    String? apiBase,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ??
            const Duration(seconds: AppConstants.aiCoachTimeoutSeconds),
        _isConfigured = (apiKey ?? AppConstants.geminiApiKey).trim().isNotEmpty,
        _model = model ?? AppConstants.geminiModel,
        _apiBase = apiBase ?? AppConstants.geminiApiBase;

  final String _model;
  final String _apiBase;
  String? _apiKeyOverride;

  /// True when `GEMINI_API_KEY` is present, i.e. real model calls are enabled.
  bool get isConfigured => _isConfigured;

  /// Asks the model for a grounded coach reply.
  ///
  /// [systemInstruction] carries the persona, guard rails and the user's data
  /// block; [userPrompt] carries the question and recent conversation.
  Future<String> generateContent({
    required String systemInstruction,
    required String userPrompt,
    double temperature = 0.6,
  }) async {
    final apiKey = (_apiKeyOverride ?? AppConstants.geminiApiKey).trim();
    if (apiKey.isEmpty) {
      throw const GeminiException(
        'GEMINI_API_KEY is not configured - using offline coach answers.',
      );
    }

    final uri = Uri.parse(
      '$_apiBase/models/$_model:generateContent?key=$apiKey',
    );

    final payload = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temperature,
        'topP': 0.95,
        'maxOutputTokens': AppConstants.aiCoachMaxOutputTokens,
      },
    });

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const GeminiException('The AI coach took too long to answer.');
    } catch (error) {
      throw GeminiException('Could not reach the AI coach: $error');
    }

    final decoded = _decode(response.body);
    if (response.statusCode != 200) {
      throw GeminiException(
        _errorMessage(decoded) ??
            'The AI coach request failed (HTTP ${response.statusCode}).',
      );
    }

    final text = _extractText(decoded);
    if (text == null || text.trim().isEmpty) {
      throw GeminiException(
        _blockReason(decoded) ?? 'The AI coach returned an empty response.',
      );
    }
    return text.trim();
  }

  /// Optional override used when the key is supplied at runtime (e.g. a
  /// premium setting) rather than through `.env`.
  void overrideApiKey(String? apiKey) => _apiKeyOverride = apiKey;

  /// Closes the underlying HTTP client.
  void dispose() => _client.close();
}
