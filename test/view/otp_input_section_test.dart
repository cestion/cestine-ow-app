import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/view/widgets/login/otp_input_section.dart';

void main() {
  testWidgets('after verify failure, pin can receive input again', (
    tester,
  ) async {
    late OtpInputSectionState otpState;
    var verifyCalls = 0;
    final verifiedCodes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInputSection(
            title: 'Enter code',
            subtitle: 'Check email',
            resendLabel: 'Resend',
            verifyingLabel: 'Verifying, please wait',
            countdownFormatter: (s) => 'Resend in ${s}s',
            onVerify: (code) async {
              verifyCalls += 1;
              verifiedCodes.add(code);
              await Future<void>.delayed(const Duration(milliseconds: 1));
              otpState.setError('Invalid code');
            },
            onResend: () async {},
          ),
        ),
      ),
    );

    otpState = tester.state<OtpInputSectionState>(find.byType(OtpInputSection));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(find.text('Verifying, please wait'), findsOneWidget);
    expect(verifyCalls, 1);

    // Finish failed verify + post-frame clear/refocus.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Invalid code'), findsOneWidget);
    expect(find.text('Verifying, please wait'), findsNothing);

    final fieldAfterError = tester.widget<TextField>(find.byType(TextField));
    expect(fieldAfterError.readOnly, isFalse);
    expect(fieldAfterError.controller?.text, isEmpty);

    // First keystroke clears error UI (red border + message).
    await tester.enterText(find.byType(TextField), '6');
    await tester.pump();
    expect(find.text('Invalid code'), findsNothing);

    // Must accept a new full code after failure.
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();
    expect(verifyCalls, 2);
    expect(verifiedCodes, ['123456', '654321']);

    // Drain the second verify's delayed setError + post-frame reset.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
  });

  testWidgets('while verifying, pin rejects edits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInputSection(
            title: 'Enter code',
            subtitle: 'Check email',
            resendLabel: 'Resend',
            verifyingLabel: 'Verifying, please wait',
            countdownFormatter: (s) => 'Resend in ${s}s',
            onVerify: (code) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
            onResend: () async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(find.text('Verifying, please wait'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '123456');
    expect(field.readOnly, isTrue);

    await tester.pump(const Duration(milliseconds: 60));
  });
}
