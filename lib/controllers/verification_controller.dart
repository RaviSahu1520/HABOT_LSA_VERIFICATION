import 'dart:async';

import 'package:flutter/widgets.dart';

import '../exceptions/lineage_exception.dart';
import '../models/verification_request.dart';
import '../services/compliance_service.dart';

enum VerificationStatus { idle, processing, quarantined, success }

class VerificationController extends ChangeNotifier {
  VerificationController({
    required this.service,
    String lsaId = defaultLsaId,
    String? predecessorId = defaultPredecessorId,
    DateTime Function()? clock,
    void Function(String message)? frictionLogger,
  }) : _clock = clock ?? DateTime.now,
       _frictionLogger = frictionLogger ?? ((message) => debugPrint(message)),
       _initialLsaId = lsaId.trim(),
       _initialPredecessorId = predecessorId?.trim() ?? '',
       lsaIdController = TextEditingController(text: lsaId.trim()),
       parentConsentCodeController = TextEditingController(),
       predecessorIdController = TextEditingController(
         text: predecessorId?.trim() ?? '',
       ) {
    parentConsentFocusNode.addListener(_handleConsentFocusChange);
    parentConsentCodeController.addListener(_handleConsentTextChange);
  }

  static const String defaultLsaId = 'LSA-7049';
  static const String defaultPredecessorId = 'PRED-9982-XYZ';

  final ComplianceVerifier service;
  final DateTime Function() _clock;
  final void Function(String message) _frictionLogger;
  final String _initialLsaId;
  final String _initialPredecessorId;

  final TextEditingController lsaIdController;
  final TextEditingController parentConsentCodeController;
  final TextEditingController predecessorIdController;
  final FocusNode parentConsentFocusNode = FocusNode();

  VerificationStatus _status = VerificationStatus.idle;
  String? _lsaIdError;
  String? _parentConsentError;
  Object? _lastFailure;
  VerificationRequest? _temporaryRequest;
  ComplianceResponse? _temporaryResponse;
  Timer? _hesitationTimer;
  DateTime? _hesitationStartedAt;
  bool _isDisposed = false;

  VerificationStatus get status => _status;

  bool get canSubmit => _status == VerificationStatus.idle;

  String? get lsaIdError => _lsaIdError;

  String? get parentConsentError => _parentConsentError;

  Object? get lastFailure => _lastFailure;

  VerificationRequest? get request => _temporaryRequest;

  ComplianceResponse? get response => _temporaryResponse;

  Future<void> verifyAndSubmit() async {
    if (!canSubmit) {
      return;
    }

    _cancelHesitationTimer();
    _clearValidationErrors();

    final lsaId = lsaIdController.text.trim();
    final parentConsentCode = parentConsentCodeController.text.trim();

    try {
      final predecessorId = requirePredecessorId();

      if (lsaId.isEmpty) {
        _lsaIdError = 'LSA ID is required.';
        _notifyListeners();
        return;
      }

      if (parentConsentCode.isEmpty) {
        _parentConsentError = 'Parent Consent Code is required.';
        _notifyListeners();
        return;
      }

      _status = VerificationStatus.processing;
      _lastFailure = null;
      _temporaryResponse = null;

      final request = VerificationRequest(
        predecessorId: predecessorId,
        lsaId: lsaId,
        parentConsentCode: parentConsentCode,
        timestampUtc: _clock().toUtc().toIso8601String(),
      );
      _temporaryRequest = request;
      _notifyListeners();

      final response = await service.verify(request);
      if (_isDisposed) {
        return;
      }

      if (response == null) {
        throw const ComplianceServiceException(
          'Compliance API returned no response.',
        );
      }

      if (!response.isValid) {
        throw const ComplianceServiceException(
          'Compliance API returned no valid compliance status.',
        );
      }

      _temporaryResponse = response;
      _status = VerificationStatus.success;
      _notifyListeners();
    } on LineageException catch (error) {
      if (!_isDisposed) {
        _quarantine(error);
      }
    } catch (error) {
      if (!_isDisposed) {
        debugPrint('[COMPLIANCE] Verification failed: $error');
        _quarantine(error);
      }
    }
  }

  String requirePredecessorId() {
    final predecessorId = predecessorIdController.text.trim();
    if (predecessorId.isEmpty) {
      throw const LineageException();
    }
    return predecessorId;
  }

  void _handleConsentFocusChange() {
    if (_isDisposed) {
      return;
    }

    if (parentConsentFocusNode.hasFocus && canSubmit) {
      _cancelHesitationTimer();
      _hesitationStartedAt = _clock();
      _hesitationTimer = Timer(const Duration(seconds: 5), _emitHesitationLog);
    } else {
      _cancelHesitationTimer();
    }
  }

  void _handleConsentTextChange() {
    if (parentConsentFocusNode.hasFocus) {
      _cancelHesitationTimer();
    }

    if (_parentConsentError != null &&
        parentConsentCodeController.text.trim().isNotEmpty) {
      _parentConsentError = null;
      _notifyListeners();
    }
  }

  void _emitHesitationLog() {
    final startedAt = _hesitationStartedAt;
    _hesitationTimer = null;
    _hesitationStartedAt = null;

    if (_isDisposed || startedAt == null || !parentConsentFocusNode.hasFocus) {
      return;
    }

    final elapsed = _clock().difference(startedAt).inMilliseconds / 1000;
    final message =
        '[UI_FRICTION_LOG] Timestamp: ${_clock().toUtc().toIso8601String()} '
        '| Field: parent_consent_code | Hesitation Duration: '
        '${elapsed.toStringAsFixed(1)}s';
    _frictionLogger(message);
  }

  void _quarantine(Object failure) {
    _lastFailure = failure;
    _temporaryRequest = null;
    _temporaryResponse = null;
    _cancelHesitationTimer();
    parentConsentFocusNode.unfocus();
    _resetForm();
    _clearValidationErrors();
    _status = VerificationStatus.quarantined;
    _notifyListeners();
  }

  void _resetForm() {
    lsaIdController.text = _initialLsaId;
    parentConsentCodeController.clear();
    predecessorIdController.text = _initialPredecessorId;
  }

  void _clearValidationErrors() {
    _lsaIdError = null;
    _parentConsentError = null;
  }

  void _cancelHesitationTimer() {
    _hesitationTimer?.cancel();
    _hesitationTimer = null;
    _hesitationStartedAt = null;
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelHesitationTimer();
    parentConsentFocusNode.removeListener(_handleConsentFocusChange);
    parentConsentCodeController.removeListener(_handleConsentTextChange);
    lsaIdController.dispose();
    parentConsentCodeController.dispose();
    predecessorIdController.dispose();
    parentConsentFocusNode.dispose();
    super.dispose();
  }
}
