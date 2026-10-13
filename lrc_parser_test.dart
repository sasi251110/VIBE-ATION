import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_ation/features/lyrics/lrc_parser.dart';

void main() {
  test('parses synced lines, multiple stamps and ignores metadata', () {
    final r = parseLyrics(
      '[ar:Someone]\n[00:01.50]Hello\n[00:05.00][00:09.25]Chorus\n',
    );
    expect(r.synced, isTrue);
    expect(r.lines.length, 3);
    expect(r.lines.first.time, const Duration(seconds: 1, milliseconds: 500));
    expect(r.lines[1].text, 'Chorus');
    expect(r.lines[2].time, const Duration(seconds: 9, milliseconds: 250));
  });

  test('plain text is not synced', () {
    final r = parseLyrics('line one\nline two');
    expect(r.synced, isFalse);
    expect(r.plain, 'line one\nline two');
  });

  test('malformed timestamps do not throw', () {
    final r = parseLyrics('[00:99.00]bad seconds\n[xx:yy]nope\n[01:00]ok');
    expect(r.lines.length, 1);
    expect(r.lines.single.time, const Duration(minutes: 1));
  });

  test('currentLineIndex', () {
    final r = parseLyrics('[00:02.00]a\n[00:04.00]b');
    expect(currentLineIndex(r.lines, const Duration(seconds: 1)), -1);
    expect(currentLineIndex(r.lines, const Duration(seconds: 3)), 0);
    expect(currentLineIndex(r.lines, const Duration(seconds: 5)), 1);
  });
}
