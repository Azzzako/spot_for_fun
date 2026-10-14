import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/ui/core/config/app_env.dart';

/// Shared spot links: `<SHARE_BASE_URL>/s/<spot-id>`.
class SpotLinks {
  SpotLinks._();

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Null when sharing isn't configured.
  static Uri? forSpot(String spotId) {
    final base = AppEnv.shareBaseUrl;
    if (base.isEmpty) return null;
    return Uri.parse('$base/s/$spotId');
  }

  /// The spot id inside one of our share links, or null for anything
  /// else (e.g. the password-recovery deep link).
  static String? spotIdFrom(Uri uri) {
    final base = AppEnv.shareBaseUrl;
    if (base.isEmpty) return null;
    final host = Uri.parse(base).host;
    if (uri.scheme != 'https' || uri.host != host) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 's') return null;
    final id = segments.last;
    return _uuid.hasMatch(id) ? id.toLowerCase() : null;
  }
}

/// A spot link that arrived before it could be opened (app still on the
/// splash, or the user not signed in yet). The shell opens it as soon as
/// it's on screen.
final pendingSpotLinkProvider = StateProvider<String?>((ref) => null);
