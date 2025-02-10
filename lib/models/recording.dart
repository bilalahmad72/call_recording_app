class Recording {
  final String path;
  final String fileName;
  final DateTime timestamp;
  final int size;
  final Duration? duration;

  Recording({
    required this.path,
    required this.fileName,
    required this.timestamp,
    required this.size,
    this.duration,
  });
}
