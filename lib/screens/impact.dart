import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// Cumulative environmental footprint — turns verified actions into visible,
/// measurable impact. Proves the SDG contribution instead of just claiming it.
class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  // (icon, value, decimals, suffix, label, sublabel, color)
  static const _metrics = [
    (Icons.cloud_done_rounded, 182.0, 0, ' kg', 'CO₂ offset', 'Across 7 trees + transport', AppColors.primary),
    (Icons.water_drop_rounded, 4200.0, 0, ' L', 'Water conserved', 'Rainwater + mindful use', Color(0xFF2E7DAF)),
    (Icons.delete_sweep_rounded, 96.0, 0, ' kg', 'Waste diverted', 'Segregated + composted', AppColors.amber),
    (Icons.park_rounded, 7.0, 0, '', 'Trees surviving', '5-year maintenance tracked', AppColors.primaryDark),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'My Impact'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Text('The real-world footprint of your verified actions.',
                        style: AppTheme.body(13.5, c: AppColors.muted)),
                    const SizedBox(height: 18),

                    // Hero total
                    GlassCard(
                      tint: AppColors.primary,
                      padding: const EdgeInsets.all(22),
                      child: Column(children: [
                        const Icon(Icons.public_rounded, color: AppColors.primaryDark, size: 32),
                        const SizedBox(height: 10),
                        const AnimatedCounter(
                            value: 182, suffix: ' kg', size: 44, color: AppColors.primaryDark),
                        Text('Total CO₂ offset to date',
                            style: AppTheme.body(13.5, w: FontWeight.w600, c: AppColors.primaryDark)),
                        const SizedBox(height: 4),
                        Text('Equivalent to charging ~22,000 phones',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(12.5, c: AppColors.primaryDark)),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Metric grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: _metrics
                          .map((m) => GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: m.$7.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12)),
                                      child: Icon(m.$1, color: m.$7, size: 24),
                                    ),
                                    const Spacer(),
                                    AnimatedCounter(
                                        value: m.$2,
                                        decimals: m.$3,
                                        suffix: m.$4,
                                        size: 26,
                                        color: m.$7),
                                    const SizedBox(height: 2),
                                    Text(m.$5, style: AppTheme.body(13.5, w: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(m.$6,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.body(12, c: AppColors.muted)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // SDG tie-in
                    GlassCard(
                      tint: AppColors.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.verified_rounded, color: AppColors.primaryDark),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Contributing to global goals',
                                style: AppTheme.display(15, c: AppColors.primaryDark))),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _SdgPill(n: 11),
                              _SdgPill(n: 12),
                              _SdgPill(n: 13),
                              _SdgPill(n: 15),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Every verified action here is auditable evidence toward '
                              'these Sustainable Development Goals.',
                              style: AppTheme.body(12.5, c: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6-month trend
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last 6 months', style: AppTheme.display(15)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 90,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _bar('Feb', 0.35),
                                _bar('Mar', 0.5),
                                _bar('Apr', 0.45),
                                _bar('May', 0.7),
                                _bar('Jun', 0.85),
                                _bar('Jul', 1.0),
                              ],
                            ),
                          ),
                        ],
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

  Widget _bar(String label, double t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: t),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Container(
            width: 26,
            height: 64 * v + 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTheme.body(12, c: AppColors.muted)),
      ],
    );
  }
}

class _SdgPill extends StatelessWidget {
  final int n;
  const _SdgPill({required this.n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.primaryDark, borderRadius: BorderRadius.circular(20)),
      child: Text('SDG $n', style: AppTheme.body(12, w: FontWeight.w700, c: Colors.white)),
    );
  }
}
