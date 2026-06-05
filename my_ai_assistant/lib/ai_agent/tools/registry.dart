import 'package:google_generative_ai/google_generative_ai.dart';
import 'definitions/team_defs.dart';
import 'definitions/personal_defs.dart';
import 'definitions/query_defs.dart';
import 'definitions/vision_defs.dart';
import 'definitions/ui_defs.dart';

final List<FunctionDeclaration> allAiTools = [
  createPersonalTaskTool,
  listPersonalTasksTool,
  createTeamTaskTool,
  updateTeamTaskTool,
  deleteTeamTaskTool,
  moveTeamTaskTool,
  joinTeamBoardTool,
  queryBoardsOverviewTool,
  queryTeamTasksTool,
  queryBoardMembersTool,
  checkBoardUpdatesTool,
  checkMemberRolesTool,
  checkConflictTool,
  analyzeUploadedImageTool,
  UIDefs.showUIContent,
];
