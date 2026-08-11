export 'package:spot_for_fun/data/repositories/auth_repository.dart'
    show authRepositoryProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/services/profile_service.dart';
import 'package:spot_for_fun/domain/mappers/profile_mapper.dart';
import 'package:spot_for_fun/domain/models/profile.dart';
import 'package:spot_for_fun/domain/user_role.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield AuthState(
    AuthChangeEvent.initialSession,
    client.auth.currentSession,
  );
  yield* client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(
    data: (s) => s.session?.user.id,
    orElse: () => null,
  );
});

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(
    data: (s) {
      final meta = s.session?.user.appMetadata;
      return UserRoleX.fromDb(meta?['role']);
    },
    orElse: () => UserRole.user,
  );
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  final service = ref.watch(profileServiceProvider);
  final dto = await service.fetchById(uid);
  return dto?.toDomain();
});
