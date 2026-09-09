import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/app_providers.dart';
import '../utils/actor_data_sync.dart';
import 'route_args.dart';
import 'route_names.dart';

/// Opens actor detail with optional list-card preview seeded into cache.
///
/// When the route pops with a successfully fetched [ActorCollection], that
/// item is upserted into the plaza and search lists (no full list refresh).
Future<void> openActorDetail(
  BuildContext context, {
  required String actorId,
  ActorCollection? preview,
  int initialTabIndex = 0,
  FutureOr<void> Function(int signedCount)? onSigned,
}) {
  final container = ProviderScope.containerOf(context);
  if (preview != null) {
    unawaited(
      container
          .read(actorRepositoryProvider)
          .seedActorCollectionDetail(preview),
    );
  }
  return Navigator.of(context)
      .pushNamed<Object?>(
        RouteNames.actorDetail,
        arguments: {
          'actorId': actorId,
          if (preview != null) 'preview': preview.toJson(),
          if (initialTabIndex != 0) 'initialTabIndex': initialTabIndex,
        },
      )
      .then<void>((result) async {
        final actor = switch (result) {
          ActorDetailResult(:final actor) => actor,
          final ActorCollection actor => actor,
          _ => null,
        };
        if (actor != null) {
          upsertActorIntoListsFromContainer(container, actor);
        }
        if (result is ActorDetailResult && result.signedCount > 0) {
          await onSigned?.call(result.signedCount);
        }
      });
}
