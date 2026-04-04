/// Stream quality tiers for adaptive degradation
enum StreamQuality {
  high,
  medium,
  low,
  audioOnly;

  String get displayName {
    switch (this) {
      case StreamQuality.high:
        return 'High Quality';
      case StreamQuality.medium:
        return 'Medium Quality';
      case StreamQuality.low:
        return 'Low Quality';
      case StreamQuality.audioOnly:
        return 'Audio Only';
    }
  }
}
