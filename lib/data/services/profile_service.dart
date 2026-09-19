import 'dart:typed_data';

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

  /// Uploads bytes to the `avatars` bucket under `<uid>.<ext>` and
  /// writes the public URL into profiles.avatar_url. Returns the
  /// updated profile. Throws if the bucket is missing or the user is
  /// not signed in.
  Future<ProfileDto> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String ext,
  }) async {
    final path = '$uid.$ext';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    final res = await _client
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', uid)
        .select()
        .single();
    return ProfileDto.fromMap(res);
  }

  /// Removes the avatar from storage (best-effort) and clears
  /// profiles.avatar_url.
  Future<ProfileDto> clearAvatar(String uid) async {
    final existing = await fetchById(uid);
    final url = existing?.avatarUrl;
    if (url != null && url.isNotEmpty) {
      try {
        await _client.storage.from('avatars').remove([url]);
      } catch (_) {
        // Object may already be gone; ignore and continue.
      }
    }
    final res = await _client
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', uid)
        .select()
        .single();
    return ProfileDto.fromMap(res);
  }
}
