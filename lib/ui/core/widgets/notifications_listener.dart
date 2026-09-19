import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/notifications_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/notification.dart';

/// Watches the realtime notifications feed and pops a SnackBar on
/// every newly arrived item. Wraps the app's router so the snackbar
/// surfaces on top of whatever screen is active.
class NotificationsListener extends ConsumerStatefulWidget {
  const NotificationsListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NotificationsListener> createState() =>
      _NotificationsListenerState();
}

class _NotificationsListenerState
    extends ConsumerState<NotificationsListener> {
  final Set<String> _seen = <String>{};
  bool _primed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsFeedProvider, (prev, next) {
      next.whenData((items) => _handleUpdate(items));
    });
    return widget.child;
  }

  void _handleUpdate(List<AppNotification> items) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!_primed) {
      _seen.addAll(items.map((n) => n.id));
      _primed = true;
      return;
    }
    for (final n in items) {
      if (_seen.add(n.id)) {
        messenger?.showSnackBar(_snackFor(n));
      }
    }
  }

  SnackBar _snackFor(AppNotification n) {
    return SnackBar(
      duration: const Duration(seconds: 4),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            n.kind.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(n.kind.body),
        ],
      ),
    );
  }
}
