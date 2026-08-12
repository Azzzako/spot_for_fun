import 'package:spot_for_fun/data/models/spot_dto.dart';
import 'package:spot_for_fun/data/models/spot_photo_dto.dart';
import 'package:spot_for_fun/data/models/spot_rating_dto.dart';
import 'package:spot_for_fun/data/models/spot_report_dto.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/domain/models/spot_report.dart';

extension SpotDtoMapper on SpotDto {
  Spot toDomain() {
    return Spot(
      id: id,
      authorId: authorId,
      name: name,
      description: description,
      lat: lat,
      lng: lng,
      type: type,
      difficulty: difficulty,
      bestTime: bestTime,
      safetyNotes: safetyNotes,
      status: status,
      rejectReason: rejectReason,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      avgRating: avgRating,
      ratingsCount: ratingsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      markerKind: markerKind,
      photos: photos.map((p) => p.toDomain()).toList(growable: false),
      authorName: authorName,
    );
  }
}

extension SpotPhotoDtoMapper on SpotPhotoDto {
  SpotPhoto toDomain() {
    return SpotPhoto(
      id: id,
      spotId: spotId,
      url: url,
      position: position,
    );
  }
}

extension SpotRatingDtoMapper on SpotRatingDto {
  SpotRating toDomain() {
    return SpotRating(
      id: id,
      spotId: spotId,
      userId: userId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      userName: userName,
    );
  }
}

extension SpotReportDtoMapper on SpotReportDto {
  SpotReport toDomain() {
    return SpotReport(
      id: id,
      spotId: spotId,
      reporterId: reporterId,
      reason: reason,
      status: status,
      createdAt: createdAt,
    );
  }
}
