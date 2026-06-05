class ResponseParser {
  static final _thinkStripRegex = RegExp(
    r'(?:<|\u003c|&lt;)(?:thinking|thought|think)(?:>|\u003e|&gt;).*?(?:(?:<|\u003c|&lt;)/(?:thinking|thought|think)(?:>|\u003e|&gt;)|$)',
    dotAll: true,
  );
  
  static final _jsonBlockRegex = RegExp(
    r'```(?:json)?\s*\{.*?\}\s*```',
    dotAll: true,
  );

  static String cleanText(String text) {
    var cleaned = text.replaceAll(_thinkStripRegex, '').trim();
    // Prevent raw JSON from leaking into the text response
    cleaned = cleaned.replaceAll(_jsonBlockRegex, '').trim();
    return cleaned;
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
      if (value is String) result[key] = value.replaceAll(thinkRegex, '').trim();
      else if (value is Map<String, dynamic>) result[key] = recursiveStripThink(value);
      else if (value is List) result[key] = value.map((e) {
        if (e is Map<String, dynamic>) return recursiveStripThink(e);
        if (e is String) return e.replaceAll(thinkRegex, '').trim();
        return e;
      }).toList();
      else result[key] = value;
    });
    return result;
  }
}

