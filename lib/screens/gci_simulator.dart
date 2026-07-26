import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// Interactive Green Contribution Index simulator.
/// Drag the four components (I, C, L, V) and watch the AHP-weighted score
/// recompute live. This demonstrates the core research contribution.
class GciSimulatorScreen extends StatefulWidget {
  const GciSimulatorScreen({super.key});

  @override
  State<GciSimulatorScreen> createState() => _GciSimulatorScreenState();
}

class _GciSimulatorScreenState extends State<GciSimulatorScreen> {
  // AHP-derived weights (sum to 1.0). Matches the research paper.
  static const wI = 0.40, wC = 0.20, wL = 0.15, wV = 0.25;

  double i = 0.82, c = 0.65, l = 0.70, v = 0.90;

  double get score => (wI * i + wC * c + wL * l + wV * v) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'GCI Simulator'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Text('Drag the factors to see how the Green Contribution Index responds.',
                        style: AppTheme.body(13.5, c: AppColors.muted)),
                    const SizedBox(height: 18),

                    // Live gauge — no key, and a short tween, so the arc tracks
                    // the sliders instead of restarting from zero each drag.
                    Center(
                      child: GlassCard(
                        radius: 120,
                        padding: const EdgeInsets.all(18),
                        child: GciGauge(
                          score: score,
                          size: 172,
                          label: 'out of 100',
                          duration: const Duration(milliseconds: 220),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GlassCard(
                      child: Column(
                        children: [
                          _factor('Environmental Impact', 'I', wI, i, AppColors.primary,
                              (x) => setState(() => i = x)),
                          _factor('Consistency', 'C', wC, c, AppColors.amber,
                              (x) => setState(() => c = x)),
                          _factor('Local Priority', 'L', wL, l, AppColors.primaryDark,
                              (x) => setState(() => l = x)),
                          _factor('Verification Confidence', 'V', wV, v, AppColors.primary,
                              (x) => setState(() => v = x)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Formula card
                    GlassCard(
                      tint: AppColors.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.functions_rounded, color: AppColors.primaryDark),
                            const SizedBox(width: 8),
                            Text('The formula', style: AppTheme.display(15, c: AppColors.primaryDark)),
                          ]),
                          const SizedBox(height: 10),
                          Text('GCI = (0.40 × I) + (0.20 × C) + (0.15 × L) + (0.25 × V)',
                              style: AppTheme.body(13.5, w: FontWeight.w600, c: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          Text('Weights derived via the Analytic Hierarchy Process (AHP) '
                              'from expert pairwise comparisons.',
                              style: AppTheme.body(12, c: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setState(() {
                        i = 0.82; c = 0.65; l = 0.70; v = 0.90;
                      }),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Center(
                          child: Text('Reset to my current values',
                              style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primary)),
                        ),
                      ),
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

  Widget _factor(String label, String tag, double weight, double value, Color color,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: AppTheme.display(13, c: color)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTheme.body(14, w: FontWeight.w600))),
            Text('w=${weight.toStringAsFixed(2)}',
                style: AppTheme.body(11.5, c: AppColors.muted)),
            const SizedBox(width: 8),
            Text(value.toStringAsFixed(2),
                style: AppTheme.display(15, c: color)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.18),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 5,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
