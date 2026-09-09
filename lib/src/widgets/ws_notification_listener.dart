import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../controller/realtime_notification_state.dart';
import '../foundation/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../provider/app_providers.dart';
import '../foundation/navigator.dart';

/// Root UI adapter for realtime notification side effects.
///
/// Connection/auth lifecycle stays in [WsController]; this widget only turns
/// a newly decoded notification into the currently required Toast.
class WsNotificationListener extends ConsumerWidget {
  final Widget child;

  const WsNotificationListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching initializes the app-scoped controller even before a feature
    // page explicitly requests realtime data.
    ref.watch(
      realtimeNotificationControllerProvider.select((state) => state.revision),
    );
    ref.listen<RealtimeNotificationState>(
      realtimeNotificationControllerProvider,
      (previous, next) {
        if (next.latestNotification == null ||
            previous?.revision == next.revision) {
          return;
        }
        final message = lookupAppLocalizations(
          StoryLocaleController.instance.current,
        ).notificationRealtimeReceived;

        void showToast() {
          final overlay =
              StoryNavigator.instance.navigatorKey.currentState?.overlay;
          if (overlay == null) return;
          StoryToast.showOnOverlay(overlay, message: message);
        }

        if (StoryNavigator.instance.navigatorKey.currentState?.overlay ==
            null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => showToast());
        } else {
          showToast();
        }
      },
    );
    return child;
  }
}
