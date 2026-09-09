import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../controller/auth_controller.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../routes/route_names.dart';
import '../foundation/navigator.dart';

/// Returns `true` if the user is authenticated.
///
/// Redirects to the login page when not authenticated. After a successful
/// login, returns `true` so the caller can continue the interrupted flow.
Future<bool> ensureLoggedInOrRedirect(
  BuildContext context,
  WidgetRef ref,
) async {
  final auth = ref.read(authControllerProvider.notifier);
  await auth.ready;
  if (auth.isLoggedIn) return true;

  if (!context.mounted) return false;
  await context.storyPush(RouteNames.login);
  if (!context.mounted) return false;

  await auth.ready;
  return auth.isLoggedIn;
}

/// Returns `true` when platform JWT **and** Privy native session are ready.
///
/// Chain operations (actor sign, pay, mint) need Privy for embedded-wallet
/// signatures. Platform [AuthController.isLoggedIn] alone is not enough —
/// mirrors web `ready && authenticated`.
///
/// Privy not ready / offline → open login (no toast). JWT is kept until a
/// definitive unauthenticated result clears it.
/// Definitive Privy logout → [AppLocalizations.authSessionExpired] + login.
Future<bool> ensurePrivySessionOrRedirect(
  BuildContext context,
  WidgetRef ref,
) async {
  final auth = ref.read(authControllerProvider.notifier);
  await auth.ready;

  if (!auth.isLoggedIn) {
    if (!context.mounted) return false;
    await context.storyPush(RouteNames.login);
    if (!context.mounted) return false;
    await auth.ready;
    if (!auth.isLoggedIn) return false;
  }

  final gate = await auth.ensurePrivySessionReady();
  switch (gate) {
    case PrivySessionGate.ready:
      return true;
    case PrivySessionGate.temporarilyUnavailable:
      // Privy unknown/offline: send user to login without toast.
      if (!context.mounted) return false;
      await context.storyPush(RouteNames.login);
      if (!context.mounted) return false;
      await auth.ready;
      if (!auth.isLoggedIn) return false;
      return (await auth.ensurePrivySessionReady()) == PrivySessionGate.ready;
    case PrivySessionGate.needsReauth:
      if (!context.mounted) return false;
      StoryToast.error(context, context.l10n.authSessionExpired);
      await context.storyPush(RouteNames.login);
      if (!context.mounted) return false;
      await auth.ready;
      if (!auth.isLoggedIn) return false;
      return (await auth.ensurePrivySessionReady()) == PrivySessionGate.ready;
  }
}
