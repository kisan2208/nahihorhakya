import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';
import '../models/action_category.dart';
import 'capture.dart';
import 'authentic_capture_screen.dart';
import 'ewaste_recycle_screen.dart';
import 'gci_detail.dart';
import 'redeem.dart';
import 'notifications.dart';
import 'impact.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Greeting row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Hi, ${DemoUser.shortName} 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(24)),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(DemoUser.ward,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(13, c: AppColors.muted)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Notifications, 2 unread',
              child: ExcludeSemantics(
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.all(11),
                  onTap: () => _push(context, const NotificationsScreen()),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.primaryDark),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hero GCI card
        Semantics(
          button: true,
          label: 'Green Contribution Index ${DemoUser.gci} out of 100, good standing, '
              'up ${DemoUser.gciDelta} this month. Tap for breakdown',
          child: ExcludeSemantics(
            child: GlassCard(
              onTap: () => _push(context, const GciDetailScreen()),
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const GciGauge(score: DemoUser.gci * 1.0, size: 128),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Green Contribution Index',
                            style: AppTheme.body(13.5, w: FontWeight.w600, c: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text('Good standing',
                            style: AppTheme.display(19, c: AppColors.primaryDark)),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.trending_up_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('+${DemoUser.gciDelta} this month',
                                style: AppTheme.body(12.5,
                                    w: FontWeight.w600, c: AppColors.primary)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text('Tap for breakdown →', style: AppTheme.body(12, c: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Wallet summary
        Semantics(
          button: true,
          label: '${DemoUser.commas(DemoUser.balance)} Green Credits, about '
              '₹${DemoUser.balanceInRupees} redeemable. Tap to redeem',
          child: ExcludeSemantics(
            child: GlassCard(
              tint: AppColors.primary,
              onTap: () => _push(context, const RedeemScreen()),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.savings_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${DemoUser.commas(DemoUser.balance)} Green Credits',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.display(20, c: AppColors.primaryDark)),
                        Text('≈ ₹${DemoUser.balanceInRupees} redeemable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(13, c: AppColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Semantics(header: true, child: Text('Quick actions', style: AppTheme.display(16))),
        const SizedBox(height: 12),
        // IntrinsicHeight so all three tiles match the tallest one — inside a
        // ListView a bare stretch Row has no bounded height to stretch to.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _quickTile(context, Icons.park_rounded, 'Plant a Tree', AppColors.primary,
                  () => _push(context, AuthenticCaptureScreen(
                        initialCategory: ActionCategory.findById('tree_planted'),
                      ))),
              const SizedBox(width: 12),
              _quickTile(context, Icons.recycling_rounded, 'Recycle\nE-Waste',
                  AppColors.primaryDark, () => _push(context, const EWasteRecycleScreen())),
              const SizedBox(width: 12),
              _quickTile(context, Icons.cleaning_services_rounded, 'Cleanliness\nDrive',
                  AppColors.amber, () => _push(context, AuthenticCaptureScreen(
                        initialCategory: ActionCategory.findById('beach_clean'),
                      ))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Impact entry
        Semantics(
          button: true,
          label: '${DemoUser.co2OffsetKg} kilograms CO2 offset. '
              'Tap to see your full environmental impact',
          child: ExcludeSemantics(
            child: GlassCard(
              tint: AppColors.accent,
              padding: const EdgeInsets.all(16),
              onTap: () => _push(context, const ImpactScreen()),
              child: Row(children: [
                const Text('🌱', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${DemoUser.co2OffsetKg} kg CO₂ offset',
                          style: AppTheme.display(16, c: AppColors.primaryDark)),
                      Text('See your full environmental impact',
                          style: AppTheme.body(12.5, c: AppColors.primaryDark)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pending task
        Semantics(
          button: true,
          label: 'Tree 3 needs a check-in. Photo due in 2 days to keep credits',
          child: ExcludeSemantics(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => _push(context, const CaptureScreen()),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.pending_actions_rounded, color: AppColors.amber),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tree #3 needs a check-in',
                          style: AppTheme.body(14.5, w: FontWeight.w700)),
                      Text('Photo due in 2 days to keep credits',
                          style: AppTheme.body(12.5, c: AppColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      ]
          .animate(interval: 70.ms)
          .fadeIn(duration: 380.ms, curve: Curves.easeOut)
          .slideY(begin: 0.14, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _quickTile(
      BuildContext c, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label.replaceAll('\n', ' '),
        child: ExcludeSemantics(
          child: GlassCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(label,
                    textAlign: TextAlign.center, style: AppTheme.body(12.5, w: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));
}
