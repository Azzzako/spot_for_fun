import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/profile_dto.dart';
import 'package:spot_for_fun/data/models/user_role.dart';
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

final currentProfileProvider = FutureProvider<ProfileDto?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final res =
      await client.from('profiles').select().eq('id', uid).maybeSingle();
  if (res == null) return null;
  return ProfileDto.fromMap(res);
});
