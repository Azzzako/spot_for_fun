import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/profile_dto.dart';
import 'package:spot_for_fun/domain/enums.dart';

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  Future<ProfileDto?> fetchById(String uid) async {
    final res =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (res == null) return null;
    return ProfileDto.fromMap(res);
  }

  Future<ProfileDto> update({
    required String uid,
    required String username,
    required String? aka,
    required String? instagram,
    required DisplayAs displayAs,
  }) async {
    final res = await _client
        .from('profiles')
        .update({
          'username': username,
          'aka': aka,
          'instagram': instagram,
          'display_as': displayAs.dbValue,
        })
        .eq('id', uid)
        .select()
        .single();
    return ProfileDto.fromMap(res);
  }

  Future<bool> isUsernameTaken(String username, {String? excludeUid}) async {
    var query = _client
        .from('profiles')
        .select('id')
        .eq('username', username);
    if (excludeUid != null) {
      query = query.neq('id', excludeUid);
    }
    final res = await query.maybeSingle();
    return res != null;
  }
}
