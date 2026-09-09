import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_slot_session.dart';

void main() {
  group('FeedSlotSession.promoteNeighbor', () {
    test('runs silence → prepare → cookies → migrate → rotate → finalize',
        () async {
      final steps = <String>[];
      final ok = await FeedSlotSession.promoteNeighbor(
        silenceOutgoing: () async => steps.add('silence'),
        prepareIncomingOnScreen: () async {
          steps.add('prepare');
          return true;
        },
        promoteCookies: () async {
          steps.add('cookies');
          return true;
        },
        migrateToActive: () async {
          steps.add('migrate');
          return true;
        },
        rotateRoles: () async {
          steps.add('rotate');
          return true;
        },
        finalizeActive: () async => steps.add('finalize'),
      );
      expect(ok, isTrue);
      expect(steps, [
        'silence',
        'prepare',
        'cookies',
        'migrate',
        'rotate',
        'finalize',
      ]);
    });

    test('aborts before migrate when cookies fail (no rotate)', () async {
      final steps = <String>[];
      final ok = await FeedSlotSession.promoteNeighbor(
        silenceOutgoing: () async => steps.add('silence'),
        prepareIncomingOnScreen: () async {
          steps.add('prepare');
          return true;
        },
        promoteCookies: () async {
          steps.add('cookies');
          return false;
        },
        migrateToActive: () async {
          steps.add('migrate');
          return true;
        },
        rotateRoles: () async {
          steps.add('rotate');
          return true;
        },
        finalizeActive: () async => steps.add('finalize'),
      );
      expect(ok, isFalse);
      expect(steps, ['silence', 'prepare', 'cookies']);
    });

    test('in-flight wait path stays promote without cold finalize', () async {
      // Mirrors chooseAdjacentActivate.waitInFlight: host may await then
      // retry promote; session itself must not skip silence/cookies.
      var cookieCalls = 0;
      final ok = await FeedSlotSession.promoteNeighbor(
        silenceOutgoing: () async {},
        prepareIncomingOnScreen: () async => true,
        promoteCookies: () async {
          cookieCalls++;
          return true;
        },
        migrateToActive: () async => true,
        rotateRoles: () async => true,
        finalizeActive: () async {},
      );
      expect(ok, isTrue);
      expect(cookieCalls, 1);
    });
  });
}
