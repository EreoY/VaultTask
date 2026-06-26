import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// Client-side DOCX (.docx) plain-text extractor.
///
/// A .docx file is a ZIP archive; the main document body lives in
/// `word/document.xml`. We unzip, decode that XML, and strip it down to
/// readable plain text so the AI can consume the contents without a
/// server round-trip.
class DocxText {
  static String extractText(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // [Process] Locate the primary document body inside the docx zip.
      ArchiveFile? docFile;
      for (final file in archive.files) {
        if (file.name == 'word/document.xml') {
          docFile = file;
          break;
        }
      }
      if (docFile == null) {
        debugPrint('[DocxText] word/document.xml not found in archive');
        return '';
      }

      final content = docFile.content;
      final xml = utf8.decode(
        content is List<int> ? content : List<int>.from(content as List),
        allowMalformed: true,
      );

      // [Process] Convert structural XML markers into plain-text equivalents.
      var text = xml
          .replaceAll('</w:p>', '\n')
          .replaceAll('</w:tr>', '\n')
          .replaceAll('</w:tab>', '\t');

      // Strip all remaining XML tags.
      text = text.replaceAll(RegExp(r'<[^>]+>'), '');

      // Unescape common XML entities.
      text = text
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");

      // Collapse excessive blank lines and trim.
      text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

      // Truncate to keep token usage bounded.
      if (text.length > 12000) {
        text = text.substring(0, 12000);
      }
      return text;
    } catch (e) {
      debugPrint('[DocxText][Error] Failed to extract docx text: $e');
      return '';
    }
  }
}
