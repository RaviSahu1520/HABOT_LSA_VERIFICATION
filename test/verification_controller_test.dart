import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:habot_lsa_verification/controllers/verification_controller.dart';
import 'package:habot_lsa_verification/exceptions/lineage_exception.dart';
import 'package:habot_lsa_verification/models/verification_request.dart';
import 'package:habot_lsa_verification/services/compliance_service.dart';

void main() {
  test('valid submission sends the request and reaches success', () async {
    final service = _FakeComplianceVerifier();
    final controller = VerificationController(
      service: service,
      clock: () => DateTime.utc(2026, 8, 7, 11, 30),
    );
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.success);
    expect(service.callCount, 1);
    expect(service.lastRequest?.predecessorId, 'PRED-9982-XYZ');
    expect(service.lastRequest?.lsaId, 'LSA-7049');
    expect(service.lastRequest?.parentConsentCode, 'PCC-2026-9901');
    expect(service.lastRequest?.timestampUtc, '2026-08-07T11:30:00.000Z');
  });

  test('missing lineage quarantines without calling the service', () async {
    final service = _FakeComplianceVerifier();
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.predecessorIdController.clear();
    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
    expect(service.callCount, 0);
    expect(controller.lastFailure, isA<LineageException>());
    expect(controller.request, isNull);
    expect(controller.response, isNull);
    expect(controller.parentConsentCodeController.text, isEmpty);
  });

  test('HTTP 500 quarantines and clears volatile form data', () async {
    final service = _FakeComplianceVerifier(
      error: const ComplianceServiceException('HTTP 500'),
    );
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
    expect(controller.parentConsentCodeController.text, isEmpty);
    expect(controller.request, isNull);
    expect(controller.response, isNull);
  });

  test('a null response status quarantines the verification', () async {
    final service = _FakeComplianceVerifier(
      response: const ComplianceResponse(
        status: null,
        payload: {'status': null},
      ),
    );
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
    expect(controller.response, isNull);
    expect(controller.parentConsentCodeController.text, isEmpty);
  });

  test('a null service response quarantines the verification', () async {
    final service = _FakeComplianceVerifier(response: null);
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
    expect(controller.request, isNull);
    expect(controller.response, isNull);
  });

  test('a malformed response failure quarantines the verification', () async {
    final service = _FakeComplianceVerifier(
      error: const ComplianceServiceException('malformed JSON'),
    );
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
    expect(controller.parentConsentCodeController.text, isEmpty);
  });

  test('timeout quarantines the verification', () async {
    final service = _FakeComplianceVerifier(error: TimeoutException('timeout'));
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    await controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.quarantined);
    expect(controller.canSubmit, isFalse);
  });

  test('duplicate submissions are ignored while processing', () async {
    final service = _BlockingComplianceVerifier();
    final controller = VerificationController(service: service);
    addTearDown(controller.dispose);

    controller.parentConsentCodeController.text = 'PCC-2026-9901';
    final firstSubmission = controller.verifyAndSubmit();
    await Future<void>.delayed(Duration.zero);
    final secondSubmission = controller.verifyAndSubmit();

    expect(controller.status, VerificationStatus.processing);
    expect(service.callCount, 1);

    service.complete();
    await Future.wait([firstSubmission, secondSubmission]);
    expect(controller.status, VerificationStatus.success);
  });
}

class _FakeComplianceVerifier implements ComplianceVerifier {
  _FakeComplianceVerifier({
    this.response = const ComplianceResponse(
      status: 'verified',
      payload: {'status': 'verified'},
    ),
    this.error,
  });

  final ComplianceResponse? response;
  final Object? error;
  int callCount = 0;
  VerificationRequest? lastRequest;

  @override
  Future<ComplianceResponse?> verify(VerificationRequest request) async {
    callCount++;
    lastRequest = request;
    if (error != null) {
      throw error!;
    }
    return response;
  }
}

class _BlockingComplianceVerifier implements ComplianceVerifier {
  final Completer<ComplianceResponse> _completer =
      Completer<ComplianceResponse>();
  int callCount = 0;

  @override
  Future<ComplianceResponse> verify(VerificationRequest request) {
    callCount++;
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      const ComplianceResponse(
        status: 'verified',
        payload: {'status': 'verified'},
      ),
    );
  }
}
