import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// Terms & Conditions + privacy summary (DPDP Act 2023 aware).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _clauses = [
    (Icons.verified_user_rounded, 'Eligibility & accounts',
        'You must be 18+ (or use a guardian-supervised account) and provide accurate '
            'information. One account per person. Ward/city details are used only to '
            'apply local environmental priorities to your Green Contribution Index.'),
    (Icons.eco_rounded, 'Earning Green Credits',
        'Credits are awarded only for actions that pass verification. Submitting false, '
            'AI-generated, duplicated or misattributed evidence is prohibited and may lead '
            'to credit reversal, a lowered trust score, or account suspension.'),
    (Icons.redeem_rounded, 'Redemption',
        'Credits have no cash value outside the platform and are non-transferable. '
            'Redemption options (bill rebates, recharge, partner discounts) depend on '
            'available sponsor funding and partner availability, and may change.'),
    (Icons.corporate_fare_rounded, 'Sponsors & CSR',
        'Reward pools may be funded by companies meeting Corporate Social Responsibility '
            'obligations. Sponsors receive aggregated, verified impact reports — never your '
            'personal identity without consent.'),
    (Icons.privacy_tip_rounded, 'Data & privacy (DPDP Act 2023)',
        'We collect photos, location and timestamps solely to verify actions. We follow '
            'consent, purpose-limitation and data-minimisation principles. You may download '
            'or delete your data at any time from Profile → Privacy & Data.'),
    (Icons.gavel_rounded, 'Fair use & liability',
        'The platform is provided on a best-effort basis. Verification technology is '
            'imperfect and decisions may be reviewed. Misuse, fraud or automated abuse '
            'may result in removal from the programme.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Terms & Conditions'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Text('Last updated: July 2026  ·  Please read before participating.',
                        style: AppTheme.body(12.5, c: AppColors.muted)),
                    const SizedBox(height: 16),
                    ..._clauses.asMap().entries.map((e) {
                      final n = e.key + 1;
                      final cl = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(9)),
                                  child: Text('$n', style: AppTheme.display(14, c: AppColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                Icon(cl.$1, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cl.$2, style: AppTheme.body(14.5, w: FontWeight.w700))),
                              ]),
                              const SizedBox(height: 10),
                              Text(cl.$3, style: AppTheme.body(13, c: AppColors.charcoal)),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    GlassCard(
                      tint: AppColors.accent,
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is a student research prototype for AAVISHKAR / ANVESHAN. '
                            'Redemption partnerships shown are illustrative.',
                            style: AppTheme.body(12.5, w: FontWeight.w600, c: AppColors.primaryDark),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'I understand',
                      icon: Icons.check_rounded,
                      onTap: () => Navigator.pop(context),
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
