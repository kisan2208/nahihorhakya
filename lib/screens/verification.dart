import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../verification_flow.dart';

/// Multi-layer verification progress -> approved result (Screens 6 & 7A).
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  static const _steps = [
    VerificationStep('Photo integrity (EXIF / GPS / time)'),
    VerificationStep('AI-generated image screen'),
    VerificationStep('Location match'),
    VerificationStep('Duplicate-image check'),
  ];

  @override
  Widget build(BuildContext context) {
    return VerificationFlow(
      steps: _steps,
      progressTitle: 'Verifying authenticity',
      progressSubtitle: 'Hang tight — running the multi-layer check.',
      resultBuilder: (context, allPassed) => VerificationResult(
        icon: Icons.check_rounded,
        badgeGradient: const [AppColors.accent, AppColors.primary],
        glowColor: AppColors.primary,
        title: 'Verified!',
        subtitle: '+100 Green Credits',
        subtitleColor: AppColors.primary,
        panel: GlassCard(
          child: Column(children: [
            // Wrap, not Row: at large text sizes the score drops to its own
            // line instead of overflowing the card.
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Verification confidence: High',
                        style: AppTheme.body(14, w: FontWeight.w700)),
                    Text('V = 0.9', style: AppTheme.display(15, c: AppColors.primary)),
                  ],
                ),
              ),
            ]),
            const Divider(height: 24),
            for (final s in _steps) _passRow(s.label),
            const Divider(height: 24),
            const SimulatedNotice(
                message: 'Scores are scripted for this prototype — no live model runs on device.'),
          ]),
        ),
        primaryLabel: 'Set first check-in reminder',
        primaryIcon: Icons.notifications_active_rounded,
        onPrimary: () => Navigator.pop(context),
        secondaryLabel: 'Done',
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  static Widget _passRow(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTheme.body(13.5, c: AppColors.charcoal)),
          ),
        ]),
      );
}
