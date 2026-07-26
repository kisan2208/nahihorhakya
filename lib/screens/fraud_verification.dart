import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../verification_flow.dart';

/// The fraud-catch demo: a gallery image is submitted, the multi-layer check
/// fails, and no credits are awarded. This proves the fraud-resistance research
/// claim on-screen.
///
/// The AI-image layer deliberately *passes* here — a re-used real photo isn't
/// AI-generated. Any single failed layer is enough to reject the submission,
/// which is the point the mixed result makes.
class FraudVerificationScreen extends StatelessWidget {
  const FraudVerificationScreen({super.key});

  static const _steps = [
    VerificationStep('Photo integrity (EXIF / GPS / time)',
        passed: false, detail: 'No location or timestamp data'),
    VerificationStep('AI-generated image screen', detail: 'No synthesis artefacts found'),
    VerificationStep('Location match', passed: false, detail: 'No GPS to match'),
    VerificationStep('Duplicate-image check',
        passed: false, detail: 'Matches an existing upload'),
  ];

  static List<VerificationStep> get _failures =>
      _steps.where((s) => !s.passed).toList();

  @override
  Widget build(BuildContext context) {
    return VerificationFlow(
      steps: _steps,
      accent: AppColors.amber,
      accentTint: AppColors.amber,
      progressTitle: 'Checking authenticity',
      progressSubtitle: 'Running the multi-layer verification on your upload.',
      resultBuilder: (context, allPassed) => VerificationResult(
        icon: Icons.gpp_bad_rounded,
        badgeGradient: const [AppColors.amber, AppColors.danger],
        glowColor: AppColors.danger,
        shake: true,
        title: 'Verification failed',
        subtitle: 'No credits awarded',
        subtitleColor: AppColors.danger,
        panel: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.report_rounded, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Why this was rejected',
                      style: AppTheme.body(14, w: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 12),
              // Derived from the failed layers, so the chips can't drift out of
              // sync with the stepper above.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in _failures) _ReasonChip(f.detail ?? f.label),
                ],
              ),
              const Divider(height: 24),
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Repeated fraud attempts lower your trust score.',
                      style: AppTheme.body(12.5, c: AppColors.muted)),
                ),
              ]),
              const SizedBox(height: 10),
              const SimulatedNotice(
                  message: 'Simulated outcome — detection is not implemented in this prototype.'),
            ],
          ),
        ),
        primaryLabel: 'Capture a real photo',
        primaryIcon: Icons.photo_camera_rounded,
        onPrimary: () => Navigator.pop(context),
        secondaryLabel: 'Learn how verification works',
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;
  const _ReasonChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
        const SizedBox(width: 5),
        // Wraps rather than overflowing the pill at large text sizes.
        Flexible(
          child: Text(label, style: AppTheme.body(12, w: FontWeight.w600, c: AppColors.danger)),
        ),
      ]),
    );
  }
}
