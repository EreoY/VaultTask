import 'dart:io';

void main() {
  var file = File('my_ai_assistant/lib/state_managers/state_chat.dart');
  var content = file.readAsStringSync();
  
  var startMarker = '    if (d.originalCall.name == \'synthetic_batch\') {';
  var endMarker = '      _draft = null;';
  
  var startIndex = content.indexOf(startMarker);
  var endIndex = content.indexOf(endMarker, startIndex);
  
  if (startIndex != -1 && endIndex != -1) {
    var newBlock = r'''    if (d.originalCall.name == 'synthetic_batch') {
      int successCount = 0;
      final List<String> errors = [];
      final List<ToolCallInfo> finalToolCalls = [];
      
      for (var t in d.tasks) {
        t.isSubmitting = true;
        notifyListeners();
        
        final Map<String, dynamic> args = {'id': t.id};
        // Use the action tracked per-item, fallback to create if missing
        String actionName = t.originalAction ?? 'create_team_task';
        
        if (actionName == 'delete_team_task') {
          // DELETE: Only needs ID
        } else if (actionName == 'move_team_task') {
          // MOVE: Needs ID and status
          args['status'] = t.column;
        } else if (t.id != null) {
          // UPDATE: Delta logic
          actionName = 'update_team_task'; // Standardize
          if (t.title != t.originalTitle) args['title'] = t.title;
          if (t.description != t.originalDescription) args['description'] = t.description;
          if (t.dueDate != t.originalDueDate) args['due_date'] = t.dueDate.toIso8601String();
          if (t.column != t.originalColumn) args['status'] = t.column;
          if (t.isCompleted != t.originalIsCompleted) args['is_completed'] = t.isCompleted;

          bool membersChanged = t.members.length != (t.originalMembers?.length ?? 0);
          if (!membersChanged && t.originalMembers != null) {
             for (var m in t.members) if (!t.originalMembers!.contains(m)) { membersChanged = true; break; }
          }
          if (membersChanged) args['members'] = t.members;

          bool labelsChanged = t.labelIds.length != (t.originalLabelIds?.length ?? 0);
          if (!labelsChanged && t.originalLabelIds != null) {
             for (var l in t.labelIds) if (!t.originalLabelIds!.contains(l)) { labelsChanged = true; break; }
          }
          if (labelsChanged) args['label_ids'] = t.labelIds;
          
          if (args.length == 1) { // No changes, skip
            t.isSubmitting = false;
            continue;
          }
        } else {
          // CREATE: Send everything
          actionName = 'create_team_task';
          args['title'] = t.title;
          args['description'] = t.description;
          args['due_date'] = t.dueDate.toIso8601String();
          args['status'] = t.column;
          args['members'] = t.members;
          args['label_ids'] = t.labelIds;
          args['board_id'] = d.boardId.isNotEmpty ? d.boardId : (d.selectedBoard?.id ?? '');
        }

        final res = await _agent.executePending(FunctionCall(actionName, args));
        if (res.contains('Error') || res.contains('Failed')) {
          errors.add('"${t.title}": $res');
        } else {
          successCount++;
          finalToolCalls.add(ToolCallInfo(name: actionName, arguments: args));
        }
        t.isSubmitting = false;
      }
''';
    content = content.replaceRange(startIndex, endIndex, newBlock);
    file.writeAsStringSync(content);
    print('submitDraft logic updated for action-aware execution.');
  }
}
