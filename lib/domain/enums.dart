enum SpotType { street, park, bowl, plaza, diy }

extension SpotTypeX on SpotType {
  String get dbValue => name;
  String get label => switch (this) {
        SpotType.street => 'Street',
        SpotType.park => 'Park',
        SpotType.bowl => 'Bowl',
        SpotType.plaza => 'Plaza',
        SpotType.diy => 'DIY',
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

