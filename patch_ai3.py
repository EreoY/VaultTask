import re

with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'r') as f:
    content = f.read()

old_scroll = """  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,"""
new_scroll = """  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0.0,"""

content = content.replace(old_scroll, new_scroll)

with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'w') as f:
    f.write(content)
