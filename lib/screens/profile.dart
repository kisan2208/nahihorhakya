import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';
import 'about.dart';
import 'terms.dart';
import 'gci_simulator.dart';
import 'certificate.dart';
import 'impact.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Semantics(header: true, child: Text('Profile', style: AppTheme.display(26))),
        const SizedBox(height: 16),

        // Identity card
        GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accent.withValues(alpha: 0.6),
                child: Text(DemoUser.name[0],
                    style: AppTheme.display(34, c: AppColors.primaryDark)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration:
                      const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(DemoUser.name, textAlign: TextAlign.center, style: AppTheme.display(20)),
            Text(DemoUser.ward,
                textAlign: TextAlign.center, style: AppTheme.body(13, c: AppColors.muted)),
            const SizedBox(height: 8),
            const GlassChip(label: 'Verified citizen', icon: Icons.shield_rounded, active: true),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats row. "Earned" is lifetime, which is higher than the current
        // balance because redemptions have already been spent out of it.
        // IntrinsicHeight so the three cards match the tallest — a bare stretch
        // Row inside a ListView has no bounded height to stretch to.
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _stat(DemoUser.commas(DemoUser.lifetimeEarned), 'Credits earned')),
            const SizedBox(width: 10),
            Expanded(child: _stat('${DemoUser.treesSurviving}', 'Trees kept')),
            const SizedBox(width: 10),
            Expanded(child: _stat('${DemoUser.gci}', 'GCI')),
          ]),
        ),
        const SizedBox(height: 20),

        _section('My Trees', [
          _row(context, Icons.eco_rounded, 'My Impact', 'View', AppColors.primary,
              onTap: () => _push(context, const ImpactScreen())),
          _row(context, Icons.park_rounded, 'Tree #1 — Neem', 'Surviving · 8 mo',
              AppColors.primary,
              onTap: () => _todo(context, 'Per-tree timeline')),
          _row(context, Icons.park_rounded, 'Tree #3 — Peepal', 'Check-in due', AppColors.amber,
              onTap: () => _todo(context, 'Tree check-in')),
        ]),
        _section('Account', [
          _row(context, Icons.card_membership_rounded, 'My Certificates', '2 issued',
              AppColors.primary,
              onTap: () => _push(context, const CertificateScreen())),
          _row(context, Icons.bolt_rounded, 'Electricity consumer no.', 'Linked ••4821',
              AppColors.primary,
              onTap: () => _todo(context, 'Manage linked utility account')),
          _row(context, Icons.phone_iphone_rounded, 'Mobile number', '+91 ••••• 6620',
              AppColors.primary,
              onTap: () => _todo(context, 'Change mobile number')),
        ]),
        _section('Privacy & Data (DPDP Act 2023)', [
          _row(context, Icons.download_rounded, 'Download my data', '', AppColors.primaryDark,
              onTap: () => _todo(context, 'Data export')),
          _row(context, Icons.tune_rounded, 'Consent controls', '', AppColors.primaryDark,
              onTap: () => _todo(context, 'Consent controls')),
          _row(context, Icons.delete_outline_rounded, 'Delete account', '', AppColors.danger,
              onTap: () => _confirmDestructive(
                    context,
                    title: 'Delete account?',
                    body: 'This erases your profile, credit history and tree records. '
                        'Credits are forfeited and this cannot be undone.',
                    confirmLabel: 'Delete account',
                  )),
        ]),
        _section('About & Legal', [
          _row(context, Icons.science_rounded, 'GCI Simulator', 'Try it', AppColors.primary,
              onTap: () => _push(context, const GciSimulatorScreen())),
          _row(context, Icons.info_outline_rounded, 'About GreenCredit', 'Why & SDGs',
              AppColors.primaryDark,
              onTap: () => _push(context, const AboutScreen())),
          _row(context, Icons.description_rounded, 'Terms & Conditions', '',
              AppColors.primaryDark,
              onTap: () => _push(context, const TermsScreen())),
        ]),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Log out',
          child: ExcludeSemantics(
            child: GlassCard(
              onTap: () => _confirmDestructive(
                context,
                title: 'Log out?',
                body: 'You\'ll need to sign in again to record actions or redeem credits.',
                confirmLabel: 'Log out',
              ),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Log out',
                    style: AppTheme.body(15, w: FontWeight.w700, c: AppColors.danger)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _push(BuildContext c, Widget s) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

  /// Honest placeholder for screens outside the prototype's scope, so a tap
  /// always produces feedback rather than appearing broken.
  void _todo(BuildContext c, String what) => ScaffoldMessenger.of(c).showSnackBar(
        SnackBar(
          content: Text('$what isn\'t part of this prototype yet.'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );

  void _confirmDestructive(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTheme.display(19)),
        content: Text(body, style: AppTheme.body(14, c: AppColors.charcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: AppTheme.body(14, w: FontWeight.w600, c: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _todo(context, confirmLabel);
            },
            child: Text(confirmLabel,
                style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Semantics(
          label: l,
          value: v,
          child: ExcludeSemantics(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(20, c: AppColors.primaryDark)),
              const SizedBox(height: 2),
              Text(l, textAlign: TextAlign.center, style: AppTheme.body(12, c: AppColors.muted)),
            ]),
          ),
        ),
      );

  Widget _section(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: AppTheme.display(15))),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(children: rows),
          ),
          const SizedBox(height: 18),
        ],
      );

  Widget _row(BuildContext context, IconData icon, String label, String trailing, Color c,
          {required VoidCallback onTap}) =>
      Semantics(
        button: true,
        label: trailing.isEmpty ? label : '$label, $trailing',
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(children: [
                Icon(icon, color: c, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppTheme.body(14.5, w: FontWeight.w600, c: c))),
                if (trailing.isNotEmpty)
                  Flexible(
                    child: Text(trailing,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(12.5, c: AppColors.muted)),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
              ]),
            ),
          ),
        ),
      );
}
