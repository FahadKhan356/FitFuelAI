import '../../../../core/domain/entities/ai_chat_message_entity.dart';
import '../../../../core/domain/entities/coach_insight.dart';
import '../models/ai_user_context_model.dart';

/// Builds the prompts that ground the AI Health Coach in the user's own data.
///
/// The context block comes straight from [AiUserContextModel.toPromptBlock],
/// so every number the model can mention is a number the app actually stored.
class AiPromptBuilder {
  const AiPromptBuilder._();

  /// How many stored exchanges are replayed so follow-up questions such as
  /// "and what about dinner?" still make sense.
  static const int historyLimit = 4;

  /// Persona, guard rails and the read-only data block. Sent as Gemini's
  /// `systemInstruction`, so it is present on every turn.
  static String systemInstruction(
    AiUserContextModel context, {
    CoachInsight? insight,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        'You are the FitFuel AI Coach, a supportive nutrition and fitness '
        'coach inside the FitFuel AI calorie-tracking app.',
      )
      ..writeln()
      ..writeln('RULES')
      ..writeln(
        '- Ground every number you mention in the USER DATA block. Never '
        'invent meals, weights, foods or targets that are not listed there.',
      )
      ..writeln(
        '- If something is missing ("not set", "nothing logged yet", "No '
        'weight entries yet"), say so briefly and ask for that log instead of '
        'guessing.',
      )
      ..writeln(
        '- Be encouraging and specific: 2-4 short sentences (or a few dashes) '
        'and finish with one concrete next action.',
      )
      ..writeln(
        '- Use metric units only (kcal, g, ml, kg) and the user\'s own '
        'numbers, never averages you made up.',
      )
      ..writeln(
        '- Never give medical advice, diagnose, or promise clinical outcomes; '
        'suggest a professional for anything medical.',
      );

    if (insight != null) {
      buffer
        ..writeln()
        ..writeln('FOCUS: ${insight.focus}');
    }

    buffer
      ..writeln()
      ..writeln('USER DATA (read-only snapshot, generated '
          '${context.generatedAt.toIso8601String()})')
      ..writeln(context.toPromptBlock());

    return buffer.toString().trim();
  }

  /// The user turn: recent conversation (oldest first), the question, and the
  /// chip prompt when the message came from a quick action.
  static String userPrompt(
    String message, {
    CoachInsight? insight,
    List<AiChatMessageEntity> history = const [],
  }) {
    final buffer = StringBuffer();

    final recent = history.take(historyLimit).toList().reversed.toList();
    if (recent.isNotEmpty) {
      buffer.writeln('RECENT CONVERSATION (oldest first)');
      for (final exchange in recent) {
        buffer.writeln('- User: ${_oneLine(exchange.message)}');
        buffer.writeln('- Coach: ${_oneLine(exchange.response)}');
      }
      buffer.writeln();
    }

    buffer.writeln('USER QUESTION');
    buffer.writeln(message.trim().isEmpty ? 'How am I doing today?' : message.trim());

    if (insight != null) {
      buffer
        ..writeln()
        ..writeln('QUICK ACTION: ${insight.label}');
    }

    buffer.writeln();
    buffer.writeln(
      'Answer using only the USER DATA above. Quote the relevant numbers in '
      'your reply.',
    );

    return buffer.toString().trim();
  }

  /// Collapses a stored message into a single prompt-friendly line.
  static String _oneLine(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
