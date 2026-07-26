import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';
import 'redeem.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Semantics(header: true, child: Text('Wallet', style: AppTheme.display(26))),
        const SizedBox(height: 16),

        // Balance hero
        GlassCard(
          tint: AppColors.primary,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.savings_rounded, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Green Credits',
                      style: AppTheme.body(14, w: FontWeight.w600, c: AppColors.primaryDark)),
                ),
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.muted),
              ]),
              const SizedBox(height: 14),
              Semantics(
                label: 'Balance',
                value: '${DemoUser.commas(DemoUser.balance)} Green Credits, '
                    'about ₹${DemoUser.balanceInRupees} redeemable',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DemoUser.commas(DemoUser.balance),
                          style: AppTheme.display(46, c: AppColors.primaryDark)),
                      Text('≈ ₹${DemoUser.balanceInRupees} redeemable',
                          style: AppTheme.body(14, c: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Redeem',
                    icon: Icons.redeem_rounded,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const RedeemScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'How credits work',
                    child: ExcludeSemantics(
                      child: Pressable(
                        onTap: () => _showHowCreditsWork(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(18)),
                          alignment: Alignment.center,
                          child: Text('How credits work',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: AppTheme.body(14,
                                  w: FontWeight.w600, c: AppColors.primaryDark)),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Month summary — both figures derived from the ledger below.
        Row(children: [
          Expanded(
              child: _summary(
                  'Earned', DemoUser.signed(DemoUser.earnedThisMonth), AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: _summary(
                  'Redeemed', DemoUser.signed(DemoUser.redeemedThisMonth), AppColors.amber)),
        ]),
        const SizedBox(height: 20),

        Semantics(header: true, child: Text('Recent activity', style: AppTheme.display(16))),
        const SizedBox(height: 12),
        ...DemoUser.ledger
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _txRow(t),
                ))
            .toList()
            .animate(interval: 60.ms)
            .fadeIn(duration: 360.ms, curve: Curves.easeOut)
            .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _txRow(DemoTx t) {
    final color = t.isEarn ? AppColors.primary : AppColors.amber;
    return Semantics(
      label: '${t.label}, ${t.date}, ${DemoUser.signed(t.delta)} credits'
          '${t.isEarn ? ', verified' : ''}',
      child: ExcludeSemantics(
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(t.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(t.label, style: AppTheme.body(14, w: FontWeight.w600))),
                    if (t.isEarn) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                    ],
                  ]),
                  Text(t.date, style: AppTheme.body(12, c: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(DemoUser.signed(t.delta), style: AppTheme.display(16, c: color)),
          ]),
        ),
      ),
    );
  }

  void _showHowCreditsWork(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            radius: 28,
            blur: 26,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text('How credits work', style: AppTheme.display(20)),
                  ),
                  const SizedBox(height: 14),
                  _bullet(Icons.verified_user_rounded,
                      'Earn only on verified actions. Every submission runs the multi-layer authenticity check first.'),
                  _bullet(Icons.trending_up_rounded,
                      'Your Green Contribution Index weights impact, consistency, local priority and verification confidence.'),
                  _bullet(Icons.currency_rupee_rounded,
                      '${DemoUser.creditsPerRupee} credits = ₹1 of redeemable value, funded from the sponsor CSR pool.'),
                  _bullet(Icons.timelapse_rounded,
                      'Tree credits stay tied to survival — miss a check-in and they can be reversed.'),
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Got it', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.body(13.5, c: AppColors.charcoal))),
        ]),
      );

  Widget _summary(String label, String value, Color c) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          label: '$label this month',
          value: '$value credits',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.body(12.5, c: AppColors.muted)),
                const SizedBox(height: 4),
                Text(value, style: AppTheme.display(20, c: c)),
                Text('this month', style: AppTheme.body(12, c: AppColors.muted)),
              ],
            ),
          ),
        ),
      );
}
