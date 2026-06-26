import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers a browser download of [content] as a UTF-8 `.md` file.
Future<void> downloadMarkdownFile(String filename, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob(<dynamic>[bytes], 'text/markdown;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
