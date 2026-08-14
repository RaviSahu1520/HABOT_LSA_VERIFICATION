import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habot_lsa_verification/models/verification_request.dart';
import 'package:habot_lsa_verification/services/assignment_mock_client.dart';
import 'package:habot_lsa_verification/services/compliance_service.dart';

void main() {
  test('posts the required headers and request body', () async {
    late http.BaseRequest capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('{"status":"verified"}', 200);
    });
    final service = ComplianceService(client: client);

    final result = await service.verify(_request());

    expect(result?.status, 'verified');
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url, ComplianceService.endpoint);
    expect(capturedRequest.headers['Content-Type'], 'application/json');
    expect(
      capturedRequest.headers['x-trace-id'],
      '8f3d1b2a-4c9e-4a11-b8d2-9901ef23a011',
    );
    expect(
      capturedRequest.headers['x-logic-hash'],
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );

    final body = jsonDecode((capturedRequest as http.Request).body);
    expect(body, {
      'predecessor_id': 'PRED-9982-XYZ',
      'lsa_id': 'LSA-7049',
      'parent_consent_code': 'PCC-2026-9901',
      'timestamp_utc': '2026-08-07T11:30:00.000Z',
    });
  });

  test('assignment mock returns success for the supplied fixture', () async {
    final service = ComplianceService(client: AssignmentMockClient.create());

    final response = await service.verify(_request());

    expect(response?.status, 'verified');
  });

  test('assignment mock returns an invalid status for other data', () async {
    final service = ComplianceService(client: AssignmentMockClient.create());
    const request = VerificationRequest(
      predecessorId: 'PRED-9982-XYZ',
      lsaId: 'LSA-7049',
      parentConsentCode: 'PCC-INVALID',
      timestampUtc: '2026-08-07T11:30:00.000Z',
    );

    final response = await service.verify(request);

    expect(response?.isValid, isFalse);
  });

  test('returns null for a JSON null response', () async {
    final service = ComplianceService(
      client: MockClient((_) async => http.Response('null', 200)),
    );

    expect(await service.verify(_request()), isNull);
  });

  test('parses a null status as an invalid response', () async {
    final service = ComplianceService(
      client: MockClient((_) async => http.Response('{"status":null}', 200)),
    );

    final response = await service.verify(_request());

    expect(response, isNotNull);
    expect(response!.status, isNull);
    expect(response.isValid, isFalse);
  });

  test('throws for an HTTP 500 response', () async {
    final service = ComplianceService(
      client: MockClient((_) async => http.Response('server error', 500)),
    );

    expect(
      () => service.verify(_request()),
      throwsA(isA<ComplianceServiceException>()),
    );
  });

  test('throws for malformed JSON', () async {
    final service = ComplianceService(
      client: MockClient((_) async => http.Response('{not-json}', 200)),
    );

    expect(
      () => service.verify(_request()),
      throwsA(isA<ComplianceServiceException>()),
    );
  });
}

VerificationRequest _request() {
  return const VerificationRequest(
    predecessorId: 'PRED-9982-XYZ',
    lsaId: 'LSA-7049',
    parentConsentCode: 'PCC-2026-9901',
    timestampUtc: '2026-08-07T11:30:00.000Z',
  );
}
