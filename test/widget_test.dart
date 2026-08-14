import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habot_lsa_verification/main.dart';
import 'package:habot_lsa_verification/controllers/verification_controller.dart';
import 'package:habot_lsa_verification/models/verification_request.dart';
import 'package:habot_lsa_verification/screens/lsa_verification_screen.dart';
import 'package:habot_lsa_verification/services/compliance_service.dart';

void main() {
  testWidgets('renders the LSA verification form', (tester) async {
    final controller = VerificationController(
      service: _FakeComplianceVerifier(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LsaVerificationScreen(controller: controller)),
    );

    expect(find.text('LSA Onboarding Gate'), findsOneWidget);
    expect(find.text('HabotConnect Data Compliance'), findsOneWidget);
    expect(find.text('LSA ID'), findsOneWidget);
    expect(find.text('Parent Consent Code'), findsOneWidget);
    expect(find.text('Predecessor ID'), findsOneWidget);
    expect(find.text('LSA-7049'), findsOneWidget);
    expect(find.text('PRED-9982-XYZ'), findsOneWidget);
    expect(find.text('Verify & Submit'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
  });

  testWidgets('valid assignment data reaches success through app wiring', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.byKey(const Key('parent-consent-code-field')),
      'PCC-2026-9901',
    );
    await tester.tap(find.byKey(const Key('verify-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Data Quarantined – Compliance Failure'), findsNothing);
  });

  testWidgets('logs one hesitation event after five seconds', (tester) async {
    final logs = <String>[];
    final controller = VerificationController(
      service: _FakeComplianceVerifier(),
      frictionLogger: logs.add,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LsaVerificationScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('parent-consent-code-field')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(logs, hasLength(1));
    expect(logs.single, contains('[UI_FRICTION_LOG]'));
    expect(logs.single, contains('Field: parent_consent_code'));
    expect(logs.single, contains('Hesitation Duration:'));
  });
}

class _FakeComplianceVerifier implements ComplianceVerifier {
  @override
  Future<ComplianceResponse?> verify(VerificationRequest request) async {
    return const ComplianceResponse(
      status: 'verified',
      payload: {'status': 'verified'},
    );
  }
}
