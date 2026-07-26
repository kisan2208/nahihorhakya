import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// About / Why this app exists — the problem, the gap, the mission, and the
/// UN Sustainable Development Goals it advances. Built for the research pitch.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // SDG goals this platform contributes to.
  static const _sdgs = [
    (11, 'Sustainable Cities & Communities',
        'Waste segregation, cleaner wards and stronger resident participation.', Color(0xFFF99D26)),
    (13, 'Climate Action',
        'Verified tree planting and lower household emissions, tracked over time.', Color(0xFF48773C)),
    (12, 'Responsible Consumption & Production',
        'Composting, recycling and e-waste handling drive a local circular economy.', Color(0xFFBF8B2E)),
    (15, 'Life on Land',
        'Survival-linked credits reward trees that actually live, not just get planted.', Color(0xFF5FA646)),
    (17, 'Partnerships for the Goals',
        'Connects citizens, municipalities, NGOs and CSR sponsors in one loop.', Color(0xFF19486A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'About GreenCredit'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    // Mission
                    GlassCard(
                      tint: AppColors.primary,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.eco_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Our mission',
                                style: AppTheme.display(17, c: AppColors.primaryDark))),
                          ]),
                          const SizedBox(height: 12),
                          Text(
                            'Reward ordinary citizens for real, verified environmental action — '
                            'and let the companies already required to fund sustainability pay for it.',
                            style: AppTheme.body(14, w: FontWeight.w600, c: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // The problem
                    _section(
                      icon: Icons.report_problem_rounded,
                      color: AppColors.amber,
                      title: 'The problem',
                      body: 'People are urged to protect the environment, but individual '
                          'eco-friendly actions — planting trees, segregating waste, composting — '
                          'earn no direct reward. Carbon markets reward industry; citizens get '
                          'nothing. So participation stays low.',
                    ),
                    const SizedBox(height: 14),

                    // The gap (the differentiator)
                    _section(
                      icon: Icons.link_off_rounded,
                      color: AppColors.primary,
                      title: 'The gap we fill',
                      body: 'India\'s Green Credit Programme already allows individuals to take '
                          'part — but there is no last-mile layer. No way to redeem effort against '
                          'an electricity bill or recharge, no hyperlocal verification for small '
                          'daily actions, and no bridge to the CSR money companies must spend. '
                          'GreenCredit builds exactly that missing layer.',
                      highlight: true,
                    ),
                    const SizedBox(height: 14),

                    // How it works loop
                    _section(
                      icon: Icons.loop_rounded,
                      color: AppColors.primaryDark,
                      title: 'How the loop works',
                      body: 'Companies fund a reward pool (meeting their mandatory CSR spend and '
                          'getting an audit-ready impact report). Citizens perform verified green '
                          'actions and earn credits. Credits are redeemed for everyday value. '
                          'Citizen acts, company funds, platform verifies.',
                    ),
                    const SizedBox(height: 20),

                    // SDG section
                    Row(children: [
                      const Icon(Icons.public_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('UN Sustainable Development Goals',
                          style: AppTheme.display(17))),
                    ]),
                    const SizedBox(height: 4),
                    Text('This project directly advances five of the 17 global goals:',
                        style: AppTheme.body(13, c: AppColors.muted)),
                    const SizedBox(height: 12),
                    ..._sdgs.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: g.$4, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('SDG',
                                        style: AppTheme.body(9.5,
                                            w: FontWeight.w700, c: Colors.white)),
                                    Text('${g.$1}', style: AppTheme.display(18, c: Colors.white)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(g.$2, style: AppTheme.body(13.5, w: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Text(g.$3, style: AppTheme.body(12, c: AppColors.muted)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        )),
                    const SizedBox(height: 8),
                    GlassCard(
                      tint: AppColors.accent,
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Text('🌏', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Small verified actions, aggregated across a community, become '
                            'measurable progress toward national and global climate targets.',
                            style: AppTheme.body(12.5, w: FontWeight.w600, c: AppColors.primaryDark),
                          ),
                        ),
                      ]),
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

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    bool highlight = false,
  }) {
    return GlassCard(
      tint: highlight ? AppColors.accent : Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AppTheme.display(16))),
          ]),
          const SizedBox(height: 12),
          Text(body, style: AppTheme.body(13.5, c: AppColors.charcoal)),
        ],
      ),
    );
  }
}
