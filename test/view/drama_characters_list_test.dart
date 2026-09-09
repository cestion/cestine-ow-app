import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/common/story_per_hour_unit_label.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/drama_detail/drama_characters_list.dart';

void main() {
  Widget wrap(List<RoleCharacter> roles, {ActorCollection? detail}) {
    return ProviderScope(
      overrides: [
        actorCollectionDetailProvider.overrideWith((ref, id) async {
          return Result.success(
            detail ??
                ActorCollection(
                  id: id,
                  currentPriceUsdc: 99,
                  computingPower: 5,
                ),
          );
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: DramaCharactersList(roles: roles)),
      ),
    );
  }

  testWidgets('shows computingPower as 片酬 + icon/h, not NFT USDC price', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        RoleCharacter.fromMap(const {
          'id': '1',
          'name': '兵马俑',
          'boundActorCollection': {
            'id': 'c-1',
            'name': '王一博',
            'computingPower': 19,
            'nft': {'unitPrice': 0.01},
          },
        }),
      ]),
    );
    await tester.pump();

    expect(find.text('片酬 19'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
    expect(find.byType(StoryPerHourUnitLabel), findsOneWidget);
    expect(find.textContaining('STORY/h'), findsNothing);
    expect(find.textContaining('99'), findsNothing);
    expect(find.textContaining('0.01'), findsNothing);
  });

  testWidgets('falls back to actor-detail computingPower when role omits pay', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        [
          RoleCharacter.fromMap(const {
            'id': '1',
            'name': '兵马俑',
            'boundActorCollection': {
              'id': 'c-1',
              'name': '王一博',
              'nft': {'unitPrice': 0.01},
            },
          }),
        ],
        detail: const ActorCollection(
          id: 'c-1',
          currentPriceUsdc: 99,
          computingPower: 19,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('片酬 19'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
    expect(find.byType(StoryPerHourUnitLabel), findsOneWidget);
    expect(find.textContaining('99'), findsNothing);
  });
}
