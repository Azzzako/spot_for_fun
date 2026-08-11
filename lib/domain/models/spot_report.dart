enum ReportStatus { open, reviewed, dismissed }

extension ReportStatusX on ReportStatus {
  String get dbValue => name;
  static ReportStatus fromDb(Object? raw) {
    return switch (raw) {
      'reviewed' => ReportStatus.reviewed,
      'dismissed' => ReportStatus.dismissed,
      _ => ReportStatus.open,
    };
  }
}

class SpotReport {
  const SpotReport({
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

  bool get isOpen => status == ReportStatus.open;
  bool get isResolved =>
      status == ReportStatus.reviewed || status == ReportStatus.dismissed;

  SpotReport copyWith({
    String? id,
    String? spotId,
    String? reporterId,
    String? reason,
    ReportStatus? status,
    DateTime? createdAt,
  }) {
    return SpotReport(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
