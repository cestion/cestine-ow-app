import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/nft/nft_sort_filters.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/repositories/actor_repository.dart';

void main() {
  testWidgets('IP plaza sort pills match lv1 pay / price order', (tester) async {
    ActorCollectionSort? tapped;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: NftSortFilters(
            currentSort: ActorCollectionSort.computingPower,
            onSortChanged: (sort) => tapped = sort,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('片酬'), findsOneWidget);
    expect(find.text('价格'), findsOneWidget);
    expect(find.text('最高片酬'), findsNothing);
    expect(find.text('完播'), findsNothing);
    expect(find.text('热度'), findsNothing);

    final payLeft = tester.getTopLeft(find.text('片酬')).dx;
    final priceLeft = tester.getTopLeft(find.text('价格')).dx;
    expect(payLeft, lessThan(priceLeft));

    await tester.tap(find.text('价格'));
    expect(tapped, ActorCollectionSort.priceAsc);
  });
}
