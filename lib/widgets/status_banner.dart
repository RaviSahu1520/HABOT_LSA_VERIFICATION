import 'package:flutter/material.dart';

import '../controllers/verification_controller.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({required this.status, super.key});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visual = _visualFor(status, colors);

    return Semantics(
      liveRegion: true,
      label: '${visual.title}: ${visual.message}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visual.backgroundColor,
          border: Border.all(color: visual.borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(visual.icon, color: visual.foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visual.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: visual.foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    visual.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: visual.foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
            if (status == VerificationStatus.processing) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: visual.foregroundColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusVisual _visualFor(VerificationStatus status, ColorScheme colors) {
    return switch (status) {
      VerificationStatus.idle => _StatusVisual(
        title: 'Idle',
        message: 'Confirm the consent code to continue onboarding.',
        icon: Icons.info_outline,
        backgroundColor: colors.surfaceContainerHighest,
        borderColor: colors.outlineVariant,
        foregroundColor: colors.onSurfaceVariant,
      ),
      VerificationStatus.processing => _StatusVisual(
        title: 'Processing',
        message: 'Checking consent and data lineage.',
        icon: Icons.sync_outlined,
        backgroundColor: colors.primaryContainer,
        borderColor: colors.primary.withValues(alpha: 0.35),
        foregroundColor: colors.onPrimaryContainer,
      ),
      VerificationStatus.quarantined => _StatusVisual(
        title: 'Quarantined',
        message: 'Data Quarantined – Compliance Failure',
        icon: Icons.gpp_bad_outlined,
        backgroundColor: colors.errorContainer,
        borderColor: colors.error.withValues(alpha: 0.35),
        foregroundColor: colors.onErrorContainer,
      ),
      VerificationStatus.success => _StatusVisual(
        title: 'Success',
        message: 'LSA onboarding compliance verified successfully.',
        icon: Icons.verified_outlined,
        backgroundColor: colors.tertiaryContainer,
        borderColor: colors.tertiary.withValues(alpha: 0.35),
        foregroundColor: colors.onTertiaryContainer,
      ),
    };
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}
