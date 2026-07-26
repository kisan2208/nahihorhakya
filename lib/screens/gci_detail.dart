import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';
import 'gci_simulator.dart';

/// Green Contribution Index breakdown (Screen 11).
class GciDetailScreen extends StatelessWidget {
  const GciDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Your GCI'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Center(child: GlassCard(
                      radius: 120,
                      padding: const EdgeInsets.all(20),
                      child: const GciGauge(
                          score: DemoUser.gci * 1.0, size: 190, label: 'out of 100'),
                    )),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How it breaks down', style: AppTheme.display(16)),
                          const SizedBox(height: 16),
                          const StatBar(
                              label: 'Environmental Impact (I)',
                              value: 0.82,
                              trailing: '0.82',
                              color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text('CO₂ & water saved by your verified actions',
                              style: AppTheme.body(11.5, c: AppColors.muted)),
                          const SizedBox(height: 16),
                          const StatBar(
                              label: 'Consistency (C)',
                              value: 0.65,
                              trailing: '0.65',
                              color: AppColors.amber),
                          const SizedBox(height: 6),
                          Text('How regularly you act over 6 months',
                              style: AppTheme.body(11.5, c: AppColors.muted)),
                          const SizedBox(height: 16),
                          const StatBar(
                              label: 'Local Priority (L)',
                              value: 0.7,
                              trailing: '0.70',
                              color: AppColors.primaryDark),
                          const SizedBox(height: 6),
                          Text('Match to Ward 12\'s environmental priorities',
                              style: AppTheme.body(11.5, c: AppColors.muted)),
                          const SizedBox(height: 16),
                          const StatBar(
                              label: 'Verification Confidence (V)',
                              value: 0.9,
                              trailing: '0.90',
                              color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text('Strength of the evidence behind your actions',
                              style: AppTheme.body(11.5, c: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      tint: AppColors.accent,
                      child: Row(children: [
                        const Icon(Icons.balance_rounded, color: AppColors.primaryDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Weights set by an expert panel via AHP.',
                              style: AppTheme.body(13, w: FontWeight.w600, c: AppColors.primaryDark)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      child: Row(children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tip', style: AppTheme.body(13, w: FontWeight.w700, c: AppColors.primary)),
                              Text('Do weekly check-ins to raise Consistency (C).',
                                  style: AppTheme.body(13, c: AppColors.charcoal)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Open GCI Simulator',
                      icon: Icons.science_rounded,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GciSimulatorScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
