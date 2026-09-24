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
  set apiKeyOverride(String? apiKey) => _apiKeyOverride = apiKey;

  /// Closes the underlying HTTP client.
  void dispose() => _client.close();

  static Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Pulls the answer text out of a `generateContent` response.
  static String? _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final text = parts
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .join('\n');
    return text.isEmpty ? null : text;
  }

  static String? _errorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map) {
      final message = error['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }

  /// Explains an empty candidate list (safety block, recitation, token cap).
  static String? _blockReason(Map<String, dynamic> decoded) {
    final feedback = decoded['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) {
      return 'The AI coach could not answer that request '
          '(${feedback['blockReason']}).';
    }
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final reason = (candidates.first as Map)['finishReason']?.toString();
      if (reason != null && reason.isNotEmpty) {
        return 'The AI coach stopped early ($reason).';
      }
    }
    return null;
  }
}
