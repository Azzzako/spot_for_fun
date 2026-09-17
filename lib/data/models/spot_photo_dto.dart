import 'package:spot_for_fun/domain/enums.dart';

class SpotPhotoDto {
  SpotPhotoDto({
    required this.id,
    required this.spotId,
    required this.url,
    required this.position,
    this.userId,
    this.reviewId,
    this.photoStatus = PhotoStatus.pending,
  });

  final String id;
  final String spotId;
  final String url;
  final int position;
  final String? userId;
  final String? reviewId;
  final PhotoStatus photoStatus;

  factory SpotPhotoDto.fromMap(Map<String, dynamic> map) {
    return SpotPhotoDto(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      url: map['url'] as String,
      position: (map['position'] as num).toInt(),
      userId: map['user_id'] as String?,
      reviewId: map['review_id'] as String?,
      photoStatus: PhotoStatusX.fromDb(map['photo_status']),
    );
  }
}
