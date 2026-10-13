class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

class ParsedLyrics {
  const ParsedLyrics({required this.lines, required this.plain});

  /// Timestamped lines, sorted by time. Empty when the lyrics are plain text.
  final List<LyricLine> lines;

  /// Lyrics text with timestamps removed.
  final String plain;

  bool get synced => lines.isNotEmpty;
  bool get isEmpty => lines.isEmpty && plain.trim().isEmpty;
}

final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _metaTag = RegExp(r'^\[[A-Za-z#]+:.*\]\s*$');

/// Parses LRC or plain text. Malformed timestamps are ignored, never thrown.
ParsedLyrics parseLyrics(String raw) {
  final lines = <LyricLine>[];
  final plain = <String>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    if (_metaTag.hasMatch(line)) continue;
    final matches = <RegExpMatch>[];
    var rest = line;
    while (true) {
      final m = _stamp.matchAsPrefix(rest);
      if (m == null) break;
      matches.add(m);
      rest = rest.substring(m.end);
    }
    final text = rest.trim();
    if (matches.isEmpty) {
      plain.add(line.trimRight());
      continue;
    }
    for (final m in matches) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      if (sec > 59) continue;
      final frac = m.group(3);
      final ms = frac == null ? 0 : int.parse(frac.padRight(3, '0'));
      lines.add(
        LyricLine(Duration(minutes: min, seconds: sec, milliseconds: ms), text),
      );
    }
    plain.add(text);
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return ParsedLyrics(lines: lines, plain: plain.join('\n').trim());
}

/// Index of the line being sung at [position], or -1 before the first line.
int currentLineIndex(List<LyricLine> lines, Duration position) {
  var idx = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].time <= position) {
      idx = i;
    } else {
      break;
    }
  }
  return idx;
}
