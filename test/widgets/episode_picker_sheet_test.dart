import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/widgets/episode_picker_sheet.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('half-sheet header has title and count, no close', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return EpisodePickerHeader(
              l10n: AppLocalizations.of(context),
              totalEpisodes: 44,
              brightness: Brightness.light,
              showClose: false,
              onClose: () {},
            );
          },
        ),
      ),
    );

    expect(find.text('选集'), findsOneWidget);
    expect(find.text('全44集'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('fullscreen header puts close on the same row as 选集', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return EpisodePickerHeader(
              l10n: AppLocalizations.of(context),
              totalEpisodes: 44,
              brightness: Brightness.light,
              showClose: true,
              onClose: () => closed = true,
            );
          },
        ),
      ),
    );

    expect(find.text('选集'), findsOneWidget);
    expect(find.text('全44集'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

    final titleY = tester.getCenter(find.text('选集')).dy;
    final closeY = tester.getCenter(find.byIcon(Icons.close)).dy;
    expect(closeY, closeTo(titleY, 2));

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });
}
