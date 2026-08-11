enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get dbValue => name;
  static UserRole fromDb(Object? raw) {
    return switch (raw) {
      'admin' => UserRole.admin,
      _ => UserRole.user,
    };
  }
}
