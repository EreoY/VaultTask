import 'package:google_generative_ai/google_generative_ai.dart';

class UIDefs {
  static final showUIContent = FunctionDeclaration(
    'show_ui_content',
    'Displays a structured UI component (table, card, list) in the chat window using JSON data. Use this for presenting task summaries or complex lists.',
    Schema.object(
      properties: {
        'title': Schema.string(description: 'The heading of the display component.'),
        'type': Schema.string(
          description: 'The visual format: table, card_list, or status_summary.',
        ),
        'data_json': Schema.string(description: 'A JSON-encoded string containing the structured data to display.'),
      },
      requiredProperties: ['title', 'type', 'data_json'],
    ),
  );
}
