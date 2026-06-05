class UIHandlers {
  static Future<String> handleShowUI(Map<String, dynamic> args) async {
    // This tool is primarily intercepted by the UI to render a special bubble.
    // The handler just confirms the data was received.
    return 'ข้อมูลสรุปถูกส่งไปยังหน้าจอแล้ว ✅';
  }
}
