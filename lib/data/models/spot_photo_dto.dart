class SpotPhotoDto {
  SpotPhotoDto({
    required this.id,
    required this.spotId,
    required this.url,
    required this.position,
  });

  final String id;
  final String spotId;
  final String url;
  final int position;

  factory SpotPhotoDto.fromMap(Map<String, dynamic> map) {
    return SpotPhotoDto(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      url: map['url'] as String,
      position: (map['position'] as num).toInt(),
    );
  }
}
