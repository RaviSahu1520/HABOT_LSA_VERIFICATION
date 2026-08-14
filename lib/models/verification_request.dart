class VerificationRequest {
  const VerificationRequest({
    required this.predecessorId,
    required this.lsaId,
    required this.parentConsentCode,
    required this.timestampUtc,
  });

  final String predecessorId;
  final String lsaId;
  final String parentConsentCode;
  final String timestampUtc;

  Map<String, dynamic> toJson() {
    return {
      'predecessor_id': predecessorId,
      'lsa_id': lsaId,
      'parent_consent_code': parentConsentCode,
      'timestamp_utc': timestampUtc,
    };
  }
}
