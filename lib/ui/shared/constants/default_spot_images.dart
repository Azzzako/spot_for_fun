const List<String> kDefaultSpotImages = [
  'assets/sample_spots/skate_01.jpg',
  'assets/sample_spots/skate_02.jpg',
  'assets/sample_spots/skate_03.jpg',
  'assets/sample_spots/skate_04.jpg',
];

String defaultSpotImageFor(String seed) {
  if (kDefaultSpotImages.isEmpty) return '';
  final h = seed.hashCode.abs();
  return kDefaultSpotImages[h % kDefaultSpotImages.length];
}