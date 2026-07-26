import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// Activity feed / notifications — check-in reminders, credit awards,
/// redemption confirmations, and peer-validation requests.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // (icon, title, body, time, color, unread)
  static const _today = [
    (Icons.pending_actions_rounded, 'Check-in due soon',
        'Tree #3 (Peepal) needs a photo in 2 days to keep its credits.', '2h ago',
        AppColors.amber, true),
    (Icons.verified_rounded, 'Action verified',
        'Your tree plantation passed all checks. +100 Green Credits added.', '5h ago',
        AppColors.primary, true),
    (Icons.groups_rounded, 'Validation request',
        'A neighbour 40m away needs a quick peer confirmation.', '6h ago',
        AppColors.primaryDark, false),
  ];

  static const _earlier = [
    (Icons.redeem_rounded, 'Redemption confirmed',
        'Electricity bill rebate of ₹50 processed. Ref #GC8842.', 'Yesterday',
        AppColors.primary, false),
    (Icons.qr_code_rounded, 'Waste QR logged',
        'Verified at Ward 12 Dry-Waste Point. +10 credits this week.', 'Yesterday',
        AppColors.amber, false),
    (Icons.workspace_premium_rounded, 'New certificate',
        'Your "Verified Green Contributor" certificate is ready to share.', '3 days ago',
        AppColors.primaryDark, false),
    (Icons.trending_up_rounded, 'GCI improved',
        'Your Green Contribution Index rose to 72 (+6 this month).', '4 days ago',
        AppColors.primary, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Notifications',
                trailing: Semantics(
                  button: true,
                  label: 'Mark all as read',
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked read'),
                          backgroundColor: AppColors.primaryDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Text('Mark all read',
                            style: AppTheme.body(12.5,
                                w: FontWeight.w600, c: AppColors.primary)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _label('Today'),
                    ..._today.map(_tile),
                    const SizedBox(height: 8),
                    _label('Earlier'),
                    ..._earlier.map(_tile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(t, style: AppTheme.display(14, c: AppColors.muted)),
      );

  Widget _tile((IconData, String, String, String, Color, bool) n) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: n.$5.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(n.$1, color: n.$5, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(n.$2, style: AppTheme.body(14, w: FontWeight.w700))),
                      if (n.$6)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(n.$3, style: AppTheme.body(12.5, c: AppColors.charcoal)),
                    const SizedBox(height: 5),
                    Text(n.$4, style: AppTheme.body(12, c: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
