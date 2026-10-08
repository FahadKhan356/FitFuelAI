import 'dart:convert';
import 'package:fitfuel_ai/features/coach/models/coach_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachResponse JSON parsing & sanitization', () {
    test('parses rich structured response matching specification', () {
      const rawJson = '''
      {
        "headline": "You're on track, but protein is behind.",
        "summary": "2,686 kcal left. Aim for 40 g protein at lunch.",
        "blocks": [
          {
            "type": "progress_bars",
            "title": "Macros today",
            "items": [
              {"label":"Protein","value":28,"target":140,"unit":"g","color":"protein"},
              {"label":"Carbs","value":7,"target":441,"unit":"g","color":"calories"}
            ]
          },
          {
            "type": "bar_chart",
            "title": "Calories this week",
            "unit": "kcal",
            "target": 3097,
            "x": ["Fri","Sat","Sun","Mon","Tue","Wed","Thu"],
            "y": [0,0,0,0,0,456,411]
          },
          {
            "type": "line_chart",
            "title": "Water, last 7 days",
            "unit": "L",
            "target": 3.0,
            "x": ["Fri","Sat","Sun","Mon","Tue","Wed","Thu"],
            "y": [1.2, 1.8, 2.0, 1.5, 2.2, 2.5, 1.5]
          },
          {
            "type": "ring",
            "title": "Calorie goal",
            "value": 411,
            "target": 3097,
            "unit": "kcal"
          },
          {
            "type": "stat_row",
            "items": [
              {"label":"Remaining","value":"2686 kcal"},
              {"label":"Streak","value":"2 days"}
            ]
          }
        ],
        "actions": [
          {"label":"Log 250 ml","icon":"water_drop","action":"log_water","payload":{"ml":250}},
          {"label":"Plan lunch","icon":"restaurant","action":"open_meal_planner","payload":{"protein_g":40}}
        ],
        "followups": ["What should I eat for dinner?", "Show my weekly protein"]
      }
      ''';

      final Map<String, dynamic> data = json.decode(rawJson) as Map<String, dynamic>;
      final response = CoachResponse.fromJson(data);

      expect(response.headline, "You're on track, but protein is behind.");
      expect(response.summary, "2,686 kcal left. Aim for 40 g protein at lunch.");
      expect(response.blocks.length, 5);

      // Verify blocks
      expect(response.blocks[0].type, 'progress_bars');
      expect(response.blocks[0].progressBars.length, 2);
      expect(response.blocks[0].progressBars[0].label, 'Protein');
      expect(response.blocks[0].progressBars[0].value, 28);
      expect(response.blocks[0].progressBars[0].target, 140);

      expect(response.blocks[1].type, 'bar_chart');
      expect(response.blocks[1].x.length, 7);
      expect(response.blocks[1].y.last, 411);

      expect(response.blocks[2].type, 'line_chart');
      expect(response.blocks[2].target, 3.0);

      expect(response.blocks[3].type, 'ring');
      expect(response.blocks[3].value, 411);
      expect(response.blocks[3].target, 3097);

      expect(response.blocks[4].type, 'stat_row');
      expect(response.blocks[4].statItems.length, 2);

      // Verify actions
      expect(response.actions.length, 2);
      expect(response.actions[0].action, CoachAction.logWater);
      expect(response.actions[0].payload['ml'], 250);
      expect(response.actions[1].action, CoachAction.openMealPlanner);
      expect(response.actions[1].payload['protein_g'], 40);

      // Verify followups
      expect(response.followups, ["What should I eat for dinner?", "Show my weekly protein"]);
    });

    test('falls back safely and cleans raw markdown markers if raw text is passed', () {
      const rawMarkdown = '''
      ```json
      {
        "headline": "**You're on track!**",
        "summary": "--- Keep it up! ---",
        "blocks": []
      }
      ```
      ''';

      final parsed = CoachResponse.parseOrFallback(rawMarkdown);
      expect(parsed.headline.contains('**'), isFalse);
      expect(parsed.summary.contains('---'), isFalse);
    });

    test('falls back to readable message on non-JSON freeform text', () {
      const nonJson = "Here is some freeform advice without valid JSON format.";
      final parsed = CoachResponse.parseOrFallback(nonJson);

      expect(parsed.headline.isNotEmpty, isTrue);
      expect(parsed.summary, contains("Here is some freeform advice"));
      expect(parsed.actions, isEmpty);
    });
  });
}
