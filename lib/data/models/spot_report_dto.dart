import 'package:spot_for_fun/domain/models/spot_report.dart';

class SpotReportDto {
  SpotReportDto({
    required this.id,
    required this.spotId,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String spotId;
  final String reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  factory SpotReportDto.fromMap(Map<String, dynamic> map) {
    return SpotReportDto(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      reporterId: map['reporter_id'] as String,
      reason: map['reason'] as String,
      status: ReportStatusX.fromDb(map['status']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
