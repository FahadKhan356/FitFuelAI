import 'dart:convert';

/// Typed action identifiers supported by the coach action buttons.
enum CoachAction {
  logWater,
  openMealPlanner,
  unknown;

  static CoachAction fromString(String? value) {
    switch (value) {
      case 'log_water':
        return CoachAction.logWater;
      case 'open_meal_planner':
        return CoachAction.openMealPlanner;
      default:
        return CoachAction.unknown;
    }
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
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return CoachResponse.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to raw text fallback
    }

    // Markdown/raw text fallback without breakages
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final String head;
    final String rest;
    if (lines.length > 1) {
      head = _sanitizeText(lines.first);
      rest = lines.sublist(1).map(_sanitizeText).join('\n');
    } else if (lines.length == 1) {
      head = 'AI Coach';
      rest = _sanitizeText(lines.first);
    } else {
      head = 'AI Coach';
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
    final blocksList = <CoachBlock>[];
    if (json['blocks'] is List) {
      for (final item in (json['blocks'] as List)) {
        if (item is Map<String, dynamic>) {
          blocksList.add(CoachBlock.fromJson(item));
        }
      }
    }

    final actionsList = <CoachActionItem>[];
    if (json['actions'] is List) {
      for (final item in (json['actions'] as List)) {
        if (item is Map<String, dynamic>) {
          actionsList.add(CoachActionItem.fromJson(item));
        }
      }
    }

    final followupsList = <String>[];
    if (json['followups'] is List) {
      for (final item in (json['followups'] as List)) {
        if (item != null) followupsList.add(item.toString());
      }
    }

    return CoachResponse(
      headline: _sanitizeText(json['headline']?.toString() ?? 'Daily Analysis'),
      summary: _sanitizeText(json['summary']?.toString() ?? ''),
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

  factory CoachActionItem.fromJson(Map<String, dynamic> json) => CoachActionItem(
        label: json['label']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        action: CoachAction.fromString(json['action']?.toString()),
        payload: json['payload'] is Map<String, dynamic>
            ? (json['payload'] as Map<String, dynamic>)
            : const {},
      );
}
