import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/chat_model.dart';

class DraftBuilder {
  static AiReply? tryBuildComposite({
    required List<FunctionCall> actionCalls,
    required String responseText,
    required List<ToolCallInfo> allToolNames,
  }) {
    if (actionCalls.isEmpty) return null;
    
    // Support aggregating any number of task-related calls
    final aggregatedTasks = <Map<String, dynamic>>[];
    String? finalBoardId;
    
    for (final call in actionCalls) {
      if (call.name == 'create_team_task' || 
          call.name == 'update_team_task' || 
          call.name == 'move_team_task' ||
          call.name == 'delete_team_task') {
          
         finalBoardId ??= call.args['board_id']?.toString() ?? call.args['team_id']?.toString();
         final taskData = Map<String, dynamic>.from(call.args);
         taskData['_original_action'] = call.name;
         aggregatedTasks.add(taskData);
      }
    }
    
    if (aggregatedTasks.isNotEmpty) {
       final compositeCall = FunctionCall('synthetic_batch', {
         'tasks': aggregatedTasks,
         'board_id': finalBoardId ?? '',
       });
       
       return AiReply(
         text: responseText.isNotEmpty ? responseText : 'ผมจัดเตรียมแผนงานทั้งหมดให้คุณตรวจสอบแล้วครับ',
         reasoning: null,
         pendingCall: compositeCall,
         toolCalls: allToolNames,
       );
    }

    // Fallback for non-task actions
    final compositeCall = actionCalls.first;
    return AiReply(
      text: responseText.isNotEmpty ? responseText : 'กรุณายืนยันการดำเนินการด้านล่างครับ',
      reasoning: null,
      pendingCall: compositeCall,
      toolCalls: allToolNames,
    );
  }
}
