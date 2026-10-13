import 'package:path/path.dart' as p;

class Track {
  const Track({
    required this.path,
    required this.title,
    this.artist = 'Unknown artist',
  });

  factory Track.fromPath(String path) =>
      Track(path: path, title: p.basenameWithoutExtension(path));

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        path: j['path'] as String,
        title: j['title'] as String,
        artist: (j['artist'] as String?) ?? 'Unknown artist',
      );

  final String path;
  final String title;
  final String artist;

  String get id => path;
  String get fileName => p.basename(path);

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'artist': artist,
      };
}
