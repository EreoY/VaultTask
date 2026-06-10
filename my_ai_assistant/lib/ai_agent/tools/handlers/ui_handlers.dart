class UIHandlers {
  static Future<String> handleShowUI(Map<String, dynamic> args) async {
    // This tool is primarily intercepted by the UI to render a special bubble.
    // The handler just confirms the data was received.
    return 'ข้อมูลสรุปถูกส่งไปยังหน้าจอแล้ว ✅';
  }

  static Future<String> handleShowTasksFromIds(
    Map<String, dynamic> args,
  ) async {
    final rawIds = args['task_ids'];
    final count = rawIds is List ? rawIds.length : 0;
    return 'รายการงานจริงจำนวน $count รายการถูกส่งไปยังหน้าจอแล้ว';
  }
}
