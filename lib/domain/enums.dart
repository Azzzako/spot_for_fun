enum SpotType {
  street,
  park,
  bowl,
  plaza,
  diy,
  skateshop,
  skatepark,
  gap,
}

extension SpotTypeX on SpotType {
  String get dbValue => name;
  String get label => switch (this) {
        SpotType.street => 'Stairs',
        SpotType.park => 'Grind',
        SpotType.bowl => 'Bowl',
        SpotType.plaza => 'Bank',
        SpotType.diy => 'DIY',
        SpotType.skateshop => 'Skateshop',
        SpotType.skatepark => 'Skatepark',
        SpotType.gap => 'Gap',
      };
  static SpotType fromDb(Object? raw) {
    return SpotType.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => SpotType.street,
    );
  }
}

enum SpotDifficulty { beginner, intermediate, advanced }

extension SpotDifficultyX on SpotDifficulty {
  String get dbValue => name;
  String get label => switch (this) {
        SpotDifficulty.beginner => 'Principiante',
        SpotDifficulty.intermediate => 'Intermedio',
        SpotDifficulty.advanced => 'Avanzado',
      };
  static SpotDifficulty fromDb(Object? raw) {
    return SpotDifficulty.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => SpotDifficulty.beginner,
    );
  }
}

enum BestTimeSlot { morning, midday, afternoon, evening, night }

extension BestTimeSlotX on BestTimeSlot {
  String get dbValue => name;
  String get label => switch (this) {
        BestTimeSlot.morning => 'Mañana',
        BestTimeSlot.midday => 'Mediodía',
        BestTimeSlot.afternoon => 'Tarde',
        BestTimeSlot.evening => 'Atardecer',
        BestTimeSlot.night => 'Noche',
      };
  static BestTimeSlot fromDb(Object? raw) {
    return BestTimeSlot.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => BestTimeSlot.morning,
    );
  }
}

enum SpotStatus { pending, approved, rejected }

extension SpotStatusX on SpotStatus {
  String get dbValue => name;
  String get label => switch (this) {
        SpotStatus.pending => 'Pendiente',
        SpotStatus.approved => 'Aprobado',
        SpotStatus.rejected => 'Rechazado',
      };
  static SpotStatus fromDb(Object? raw) {
    return SpotStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => SpotStatus.pending,
    );
  }
}

enum MarkerKind { street, park, bowl, ledge, skateshop }

extension MarkerKindX on MarkerKind {
  String get dbValue => name;
  String get label => switch (this) {
        MarkerKind.street => 'Street',
        MarkerKind.park => 'Park',
        MarkerKind.bowl => 'Bowl',
        MarkerKind.ledge => 'Ledge',
        MarkerKind.skateshop => 'Skateshop',
      };
  static MarkerKind fromDb(Object? raw) {
    return MarkerKind.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => MarkerKind.street,
    );
  }
}

enum DisplayAs { username, aka }

extension DisplayAsX on DisplayAs {
  String get dbValue => name;
  String get label => switch (this) {
        DisplayAs.username => 'Nombre',
        DisplayAs.aka => 'A.K.A',
      };
  static DisplayAs fromDb(Object? raw) {
    return DisplayAs.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => DisplayAs.username,
    );
  }
}

enum ReviewStatus { pending, approved, rejected }

extension ReviewStatusX on ReviewStatus {
  String get dbValue => name;
  String get label => switch (this) {
        ReviewStatus.pending => 'En revisión',
        ReviewStatus.approved => 'Aprobada',
        ReviewStatus.rejected => 'Rechazada',
      };
  static ReviewStatus fromDb(Object? raw) {
    return ReviewStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => ReviewStatus.pending,
    );
  }
}

enum PhotoStatus { pending, approved, rejected }

extension PhotoStatusX on PhotoStatus {
  String get dbValue => name;
  String get label => switch (this) {
        PhotoStatus.pending => 'En revisión',
        PhotoStatus.approved => 'Aprobada',
        PhotoStatus.rejected => 'Rechazada',
      };
  static PhotoStatus fromDb(Object? raw) {
    return PhotoStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => PhotoStatus.pending,
    );
  }
}

enum NotificationKind {
  ratingApproved,
  ratingRejected,
  photoApproved,
  photoRejected,
}

extension NotificationKindX on NotificationKind {
  String get dbValue => switch (this) {
        NotificationKind.ratingApproved => 'rating_approved',
        NotificationKind.ratingRejected => 'rating_rejected',
        NotificationKind.photoApproved => 'photo_approved',
        NotificationKind.photoRejected => 'photo_rejected',
      };
  String get title => switch (this) {
        NotificationKind.ratingApproved => 'Reseña aprobada',
        NotificationKind.ratingRejected => 'Reseña rechazada',
        NotificationKind.photoApproved => 'Foto aprobada',
        NotificationKind.photoRejected => 'Foto rechazada',
      };
  String get body => switch (this) {
        NotificationKind.ratingApproved =>
          'Tu reseña ya es pública. ¡Gracias por contribuir!',
        NotificationKind.ratingRejected =>
          'Tu reseña fue rechazada. Revisa las reglas y vuelve a intentarlo.',
        NotificationKind.photoApproved =>
          'Tu foto ya es visible en el spot.',
        NotificationKind.photoRejected =>
          'Tu foto fue rechazada. Sube una toma diferente.',
      };
  static NotificationKind fromDb(Object? raw) {
    return switch (raw) {
      'rating_approved' => NotificationKind.ratingApproved,
      'rating_rejected' => NotificationKind.ratingRejected,
      'photo_approved' => NotificationKind.photoApproved,
      'photo_rejected' => NotificationKind.photoRejected,
      _ => NotificationKind.ratingApproved,
    };
  }
}

