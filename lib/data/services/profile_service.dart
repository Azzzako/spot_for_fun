import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/profile_dto.dart';

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  Future<ProfileDto?> fetchById(String uid) async {
    final res =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (res == null) return null;
    return ProfileDto.fromMap(res);
  }
}
