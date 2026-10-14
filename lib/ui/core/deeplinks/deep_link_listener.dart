import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/ui/core/deeplinks/spot_links.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';

/// Opens shared spot links (App Links). Signed in and past the splash:
/// push the spot right away. Otherwise park it in
/// [pendingSpotLinkProvider]; AppShell opens it once the user lands on
/// the map.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _lastLink;
  DateTime? _lastLinkAt;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(_handle);
    // Cold start: depending on the plugin version the stream may or may
    // not replay the launch link, so ask for it too (_handle dedupes).
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handle(uri);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handle(Uri uri) {
    final spotId = SpotLinks.spotIdFrom(uri);
    if (spotId == null || !mounted) return;
    // The launch link can arrive twice (stream + getInitialLink); the same
    // link opened again later must still work.
    final now = DateTime.now();
    final link = uri.toString();
    if (link == _lastLink &&
        _lastLinkAt != null &&
        now.difference(_lastLinkAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastLink = link;
    _lastLinkAt = now;

    final router = ref.read(goRouterProvider);
    final session = ref.read(authStateProvider).valueOrNull?.session;
    final location = router.routerDelegate.currentConfiguration.uri.path;
    final booting = location == AppRoutes.splash ||
        location == AppRoutes.onboarding;

    if (session == null || booting) {
      ref.read(pendingSpotLinkProvider.notifier).state = spotId;
      return;
    }
    router.push(AppRoutes.spotDetail(spotId));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
