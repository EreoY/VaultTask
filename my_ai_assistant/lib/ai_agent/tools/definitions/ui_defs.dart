import 'package:google_generative_ai/google_generative_ai.dart';

class UIDefs {
  static final showUIContent = FunctionDeclaration(
    'show_ui_content',
    'Displays a structured UI component (table, card, list) in the chat window using JSON data. Use this for plan reviews, empty states, or generated data that does not already exist as real tasks. For existing tasks, use show_tasks_from_ids instead.',
    Schema.object(
      properties: {
        'title': Schema.string(
          description: 'The heading of the display component.',
        ),
        'type': Schema.string(
          description:
              'The visual format: table, card_list, or status_summary.',
        ),
        'data_json': Schema.string(
          description:
              'A JSON-encoded string containing the structured data to display.',
        ),
      },
      requiredProperties: ['title', 'type', 'data_json'],
    ),
  );

  static final showTasksFromIds = FunctionDeclaration(
    'show_tasks_from_ids',
    'Displays real existing tasks by ID. Use this after query_team_tasks or whenever the tasks already exist in the system. Only pass task IDs; the app will look up workspace, board, assignees, status, and deadline itself.',
    Schema.object(
      properties: {
        'title': Schema.string(
          description: 'The heading of the task results component.',
        ),
        'task_ids': Schema.array(
          description: 'IDs of existing tasks to render.',
          items: Schema.string(description: 'Existing task ID.'),
        ),
      },
      requiredProperties: ['title', 'task_ids'],
    ),
  );
}
