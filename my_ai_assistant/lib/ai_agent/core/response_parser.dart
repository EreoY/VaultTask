class ResponseParser {
  static final _thinkStripRegex = RegExp(
    r'(?:<|\u003c|&lt;)(?:thinking|thought|think)(?:>|\u003e|&gt;).*?(?:(?:<|\u003c|&lt;)/(?:thinking|thought|think)(?:>|\u003e|&gt;)|$)',
    dotAll: true,
  );

  static final _jsonBlockRegex = RegExp(
    r'```(?:json)?\s*\{.*?\}\s*```',
    dotAll: true,
  );

  static final _channelLeakRegex = RegExp(r'<\|[^|>]+?\|>', dotAll: true);

  // Malformed / variant gpt-oss "harmony" channel reasoning markers.
  // Tolerates a pipe on only one side (e.g. `<|channel>`, `<channel|>`) or
  // both sides (`<|channel|>`), optional inner spaces, and is case-insensitive.
  // The trailing optional group also consumes the channel keyword that rides
  // directly after a marker (e.g. `<|channel|>analysis`, `<|channel>thought`)
  // so the reasoning label is removed ONLY when adjacent to a marker — never
  // from normal Thai/English prose.
  static final _harmonyMarkerRegex = RegExp(
    r'<\|?\s*(?:channel|message|start|end|return|constrain|assistant|user|system)\s*\|?>\s*(?:thought|analysis|commentary|final)?',
    caseSensitive: false,
  );

  // Leftover orphan channel keyword sitting alone on its own line after marker
  // removal. Whole-line match only — safe against legitimate prose content.
  static final _orphanChannelWordRegex = RegExp(
    r'^[ \t]*(?:thought|analysis|commentary|final)[ \t]*$',
    caseSensitive: false,
    multiLine: true,
  );

  // Collapse the empty lines created by the removals above.
  static final _blankLineCollapseRegex = RegExp(r'\n{3,}');

  static String cleanText(String text) {
    var cleaned = text.replaceAll(_thinkStripRegex, '').trim();
    // Strip malformed / variant harmony channel markers + any adjacent keyword.
    cleaned = cleaned.replaceAll(_harmonyMarkerRegex, ' ');
    // Remove any channel keyword left orphaned on its own line by the removal.
    cleaned = cleaned.replaceAll(_orphanChannelWordRegex, '');
    // Strip any remaining well-formed `<|...|>` channel tokens.
    cleaned = cleaned.replaceAll(_channelLeakRegex, ' ');
    // Prevent raw JSON from leaking into the text response.
    cleaned = cleaned.replaceAll(_jsonBlockRegex, '');
    // Collapse the now-empty leading/trailing whitespace and blank lines.
    cleaned = cleaned.replaceAll(_blankLineCollapseRegex, '\n\n');
    return cleaned.trim();
  }

  static String extractTextFromParts(List<dynamic> parts) {
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map && p.containsKey('text')) {
        buf.write(p['text']);
      }
      // Explicitly ignore thoughtSignature
    }
    return buf.toString();
  }

  static Map<String, dynamic> recursiveStripThink(Map<String, dynamic> args) {
    final Map<String, dynamic> result = {};
    final thinkRegex = RegExp(r'<think>.*?(?:</think>|$)', dotAll: true);
    args.forEach((key, value) {
      if (value is String) {
        result[key] = value.replaceAll(thinkRegex, '').trim();
      } else if (value is Map<String, dynamic>)
        result[key] = recursiveStripThink(value);
      else if (value is List)
        result[key] = value.map((e) {
          if (e is Map<String, dynamic>) return recursiveStripThink(e);
          if (e is String) return e.replaceAll(thinkRegex, '').trim();
          return e;
        }).toList();
      else
        result[key] = value;
    });
    return result;
  }
}
