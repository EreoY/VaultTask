// Non-web stub. Native platforms have no browser download; the caller falls
// back to copying the markdown to the clipboard instead.
Future<void> downloadMarkdownFile(String filename, String content) async {
  // No-op on non-web platforms.
}
