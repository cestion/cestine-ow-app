import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/nft/actor_how_to_play_dialog.dart';
import 'package:story_app/src/components/nft/nft_plaza_chrome.dart';
import 'package:story_app/src/l10n/app_localizations.dart';

Widget _wrap(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: home,
    ),
  );
}

void main() {
  testWidgets('IP plaza nav has menu, search and help icons', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          appBar: AppBar(
            leading: const NftPlazaNavLeading(),
            actions: const [NftPlazaNavActions()],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('nft-plaza-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('nft-plaza-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nft-plaza-help')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('help icon opens how-to-play sheet with sign/issue tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          appBar: AppBar(
            leading: const NftPlazaNavLeading(),
            actions: const [NftPlazaNavActions()],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('nft-plaza-help')));
    await tester.pumpAndSettle();

    expect(find.byType(ActorHowToPlayDialog), findsOneWidget);
    expect(find.text('角色 IP 怎么玩'), findsOneWidget);
    expect(find.text('签约IP'), findsOneWidget);
    expect(find.text('发行IP'), findsOneWidget);
    expect(find.text('去创作'), findsNothing);

    await tester.tap(find.text('发行IP'));
    await tester.pump();

    expect(find.text('去创作'), findsOneWidget);
    expect(find.text('三重收益'), findsOneWidget);
  });
}
