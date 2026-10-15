import 'dart:convert';

/// Typed action identifiers supported by the coach action buttons.
enum CoachAction {
  logWater,
  openMealPlanner,
  unknown;

  static CoachAction fromString(String? value) {
    if (value == null) return CoachAction.unknown;
    final v = value.toLowerCase();
    if (v.contains('water')) {
      return CoachAction.logWater;
    }
    if (v.contains('meal') || v.contains('plan') || v.contains('lunch') || v.contains('dinner')) {
      return CoachAction.openMealPlanner;
    }
    return CoachAction.unknown;
  }
}

/// A structured response returned by the AI Coach.
class CoachResponse {
  const CoachResponse({
    required this.headline,
    required this.summary,
    this.blocks = const [],
    this.actions = const [],
    this.followups = const [],
    this.isRawFallback = false,
  });

  final String headline;
  final String summary;
  final List<CoachBlock> blocks;
  final List<CoachActionItem> actions;
  final List<String> followups;
  final bool isRawFallback;

  /// Safely parses raw text (either strict JSON, JSON inside fences, or raw text fallback).
  factory CoachResponse.parseOrFallback(String text) => CoachResponse.parse(text);

  factory CoachResponse.parse(String text) {
    if (text.trim().isEmpty) {
      return const CoachResponse(
        headline: 'No response received',
        summary: 'Please try asking again.',
        isRawFallback: true,
      );
    }

    String cleaned = text.trim();

    // 1. Strip markdown fences if present
    cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$', multiLine: true), '');
    cleaned = cleaned.trim();

    // 2. Try to isolate pure JSON if surrounded by extraneous text
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      final jsonCandidate = cleaned.substring(firstBrace, lastBrace + 1).trim();
      try {
        final decoded = jsonDecode(jsonCandidate);
        if (decoded is Map<String, dynamic>) {
          return CoachResponse.fromJson(decoded);
        }
      } catch (_) {
        // Continue to resilient parsing
      }
    }

    // 3. Try decoding the cleaned string directly
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return CoachResponse.fromJson(decoded);
      }
    } catch (_) {
      // Continue to resilient regex extraction
    }

    // 4. Resilient regex extraction for truncated or slightly malformed JSON
    final headlineMatch = RegExp(r'"headline"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"').firstMatch(cleaned);
    final summaryMatch = RegExp(r'"summary"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"').firstMatch(cleaned);

    if (headlineMatch != null || summaryMatch != null) {
      final head = headlineMatch?.group(1) ?? 'AI Coach Insight';
      var rest = summaryMatch?.group(1) ?? '';

      // If summary was cut off before closing quote, extract whatever followed "summary": "
      if (rest.isEmpty) {
        final summaryOpenMatch = RegExp(r'"summary"\s*:\s*"([^"\n\r]*)').firstMatch(cleaned);
        if (summaryOpenMatch != null) {
          rest = summaryOpenMatch.group(1) ?? '';
        }
      }

      // Extract any followups if available
      final followupsList = <String>[];
      final followupMatches = RegExp(r'"(?:followups|questions)"\s*:\s*\[([^\]]*)\]').firstMatch(cleaned);
      if (followupMatches != null) {
        final inside = followupMatches.group(1) ?? '';
        final items = RegExp(r'"([^"\\]*(?:\\.[^"\\]*)*)"').allMatches(inside);
        for (final m in items) {
          final str = m.group(1);
          if (str != null && str.isNotEmpty) followupsList.add(str);
        }
      }

      return CoachResponse(
        headline: _sanitizeText(head),
        summary: _sanitizeText(rest),
        isRawFallback: false,
        followups: followupsList.isNotEmpty
            ? followupsList
            : const [
                "How is my calorie balance today?",
                "Show my weekly calories",
                "How is my hydration?"
              ],
      );
    }

    // 5. Plain text fallback: Clean out any markdown ticks, braces, or JSON markers
    final sanitized = cleaned
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll(RegExp(r'^\s*\{\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*\}\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'"(headline|summary)"\s*:\s*'), '')
        .trim();

    final lines = sanitized
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '{' && l != '}' && !l.startsWith('```'))
        .toList();

    final String head;
    final String rest;
    if (lines.length > 1) {
      head = _sanitizeText(lines.first);
      rest = lines.sublist(1).map(_sanitizeText).join('\n');
    } else if (lines.length == 1) {
      head = 'AI Coach Insight';
      rest = _sanitizeText(lines.first);
    } else {
      head = 'AI Coach Insight';
      rest = '';
    }

    return CoachResponse(
      headline: head,
      summary: rest,
      isRawFallback: true,
      followups: const [
        "How is my calorie balance today?",
        "Show my weekly calories",
        "How is my hydration?"
      ],
    );
  }

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error') ||
        json['code'] == 'NOT_FOUND' ||
        (json['headline'] == null && json['blocks'] == null && json['summary'] == null)) {
      throw FormatException('Invalid coach response or error payload: $json');
    }

    final blocksList = <CoachBlock>[];
    if (json['blocks'] is List) {
      for (final item in (json['blocks'] as List)) {
        if (item is Map<String, dynamic>) {
          blocksList.add(CoachBlock.fromJson(item));
        } else if (item is Map) {
          blocksList.add(CoachBlock.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    final actionsList = <CoachActionItem>[];
    if (json['actions'] is List) {
      for (final item in (json['actions'] as List)) {
        if (item is Map<String, dynamic>) {
          actionsList.add(CoachActionItem.fromJson(item));
        } else if (item is Map) {
          actionsList.add(CoachActionItem.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    final followupsList = <String>[];
    if (json['followups'] is List) {
      for (final item in (json['followups'] as List)) {
        if (item is String) {
          followupsList.add(item);
        } else if (item is Map) {
          final q = item['question'] ?? item['title'] ?? item['prompt'] ?? item['text'];
          if (q != null) followupsList.add(q.toString());
        } else if (item != null) {
          followupsList.add(item.toString());
        }
      }
    }

    final rawHeadline = json['headline']?.toString() ?? '';
    final rawSummary = json['summary']?.toString() ?? '';

    final head = rawHeadline.isNotEmpty
        ? rawHeadline
        : (rawSummary.isNotEmpty ? 'Coach Insight' : 'Daily Nutrition Overview');

    return CoachResponse(
      headline: _sanitizeText(head),
      summary: _sanitizeText(rawSummary),
      blocks: blocksList,
      actions: actionsList,
      followups: followupsList,
    );
  }

  static String _sanitizeText(String input) {
    // Strips unwanted raw markdown symbols like ** or ---
    return input.replaceAll('**', '').replaceAll('---', '').replaceAll('###', '').trim();
  }
}

/// A structured visual block (progress_bars, bar_chart, line_chart, ring, stat_row).
class CoachBlock {
  const CoachBlock({
    required this.type,
    this.title = '',
    this.unit = '',
    this.target = 0,
    this.value = 0,
    this.items = const [],
    this.x = const [],
    this.y = const [],
  });

  final String type; // 'progress_bars', 'bar_chart', 'line_chart', 'ring', 'stat_row'
  final String title;
  final String unit;
  final double target;
  final double value;
  final List<dynamic> items;
  final List<String> x;
  final List<double> y;

  List<CoachProgressBarItem> get progressBars =>
      items.whereType<CoachProgressBarItem>().toList();

  List<CoachStatRowItem> get statItems =>
      items.whereType<CoachStatRowItem>().toList();

  factory CoachBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final unit = json['unit']?.toString() ?? '';
    final target = _toDouble(json['target']);
    final value = _toDouble(json['value']);

    final itemsList = <dynamic>[];
    if (json['items'] is List) {
      for (final it in (json['items'] as List)) {
        if (it is Map<String, dynamic>) {
          if (type == 'progress_bars') {
            itemsList.add(CoachProgressBarItem.fromJson(it));
          } else if (type == 'stat_row') {
            itemsList.add(CoachStatRowItem.fromJson(it));
          } else {
            itemsList.add(it);
          }
        }
      }
    }

    final xList = <String>[];
    if (json['x'] is List) {
      for (final item in (json['x'] as List)) {
        xList.add(item?.toString() ?? '');
      }
    }

    final yList = <double>[];
    if (json['y'] is List) {
      for (final item in (json['y'] as List)) {
        yList.add(_toDouble(item));
      }
    }

    return CoachBlock(
      type: type,
      title: title,
      unit: unit,
      target: target,
      value: value,
      items: itemsList,
      x: xList,
      y: yList,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}

class CoachProgressBarItem {
  const CoachProgressBarItem({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final String unit;
  final String color; // 'protein', 'calories', 'water'

  factory CoachProgressBarItem.fromJson(Map<String, dynamic> json) =>
      CoachProgressBarItem(
        label: json['label']?.toString() ?? '',
        value: CoachBlock._toDouble(json['value']),
        target: CoachBlock._toDouble(json['target']),
        unit: json['unit']?.toString() ?? '',
        color: json['color']?.toString() ?? 'calories',
      );
}

class CoachStatRowItem {
  const CoachStatRowItem({required this.label, required this.value});
  final String label;
  final String value;

  factory CoachStatRowItem.fromJson(Map<String, dynamic> json) => CoachStatRowItem(
        label: json['label']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
      );
}

class CoachActionItem {
  const CoachActionItem({
    required this.label,
    required this.icon,
    required this.action,
    this.payload = const {},
  });

  final String label;
  final String icon;
  final CoachAction action;
  final Map<String, dynamic> payload;

  factory CoachActionItem.fromJson(Map<String, dynamic> json) {
    final actionStr = json['action']?.toString() ?? json['type']?.toString();
    final action = CoachAction.fromString(actionStr);
    var label = json['label']?.toString() ??
        json['title']?.toString() ??
        json['prompt']?.toString() ??
        '';
    if (label.isEmpty) {
      label = action == CoachAction.logWater ? 'Log 250 ml' : 'Plan meal';
    }
    final icon = (json['icon']?.toString().isNotEmpty == true)
        ? json['icon']!.toString()
        : (action == CoachAction.logWater ? 'water_drop' : 'restaurant');

    final payloadData = <String, dynamic>{};
    if (json['payload'] is Map) {
      payloadData.addAll((json['payload'] as Map).cast<String, dynamic>());
    } else {
      if (json['amount_ml'] != null) payloadData['ml'] = json['amount_ml'];
      if (json['protein_g'] != null) payloadData['protein_g'] = json['protein_g'];
    }

    return CoachActionItem(
      label: label,
      icon: icon,
      action: action,
      payload: payloadData,
    );
  }
}
