import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';

/// Redemption marketplace + confirmation (Screens 12 & 13).
class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Redeem credits'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    GlassCard(
                      tint: AppColors.primary,
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.corporate_fare_rounded, color: AppColors.primaryDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Reward pool sponsored by TataGreen CSR',
                              style:
                                  AppTheme.body(13, w: FontWeight.w600, c: AppColors.primaryDark)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          'Balance: ${DemoUser.commas(DemoUser.balance)} credits '
                          '≈ ₹${DemoUser.balanceInRupees}',
                          style: AppTheme.body(13, c: AppColors.muted)),
                    ),
                    // A fixed childAspectRatio clips these cards once the OS
                    // text size grows, so lay them out at an intrinsic height
                    // instead of forcing a ratio.
                    LayoutBuilder(builder: (context, c) {
                      const gap = 12.0;
                      final colWidth = (c.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final o in demoRedeemOptions)
                            SizedBox(width: colWidth, child: _optionCard(context, o)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context, RedeemOption o) {
    final affordable = DemoUser.balance >= o.minCredits;
    final enabled = o.available && affordable;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '${o.flatTitle}, from ${o.minCredits} credits, '
          '${!o.available ? 'coming soon' : affordable ? 'available' : 'not enough credits'}',
      child: ExcludeSemantics(
        child: GlassCard(
          onTap: enabled ? () => _confirm(context, o) : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(o.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(o.title, style: AppTheme.body(14, w: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('from ${o.minCredits} cr',
                  style: AppTheme.body(12, w: FontWeight.w600, c: AppColors.primary)),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: GlassChip(
                  label: !o.available
                      ? 'Coming soon'
                      : affordable
                          ? 'Available'
                          : 'Need ${o.minCredits - DemoUser.balance} more',
                  color: o.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, RedeemOption option) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(option: option),
    );
  }
}

class _ConfirmSheet extends StatefulWidget {
  final RedeemOption option;
  const _ConfirmSheet({required this.option});

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _done = false;

  /// Spends the option's own minimum, not a hardcoded 500.
  int get _spend => widget.option.minCredits;
  int get _newBalance => DemoUser.balance - _spend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            radius: 28,
            blur: 26,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: _done ? _success() : _form()),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: Text('Redeem $_spend credits', style: AppTheme.display(20)),
        ),
        Text('for ${DemoUser.rupeesFor(_spend)} — ${widget.option.flatTitle.toLowerCase()}',
            style: AppTheme.body(14, c: AppColors.muted)),
        const SizedBox(height: 18),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Consumer / account number',
            hintText: 'e.g. 4821000123',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Confirm redemption',
          icon: Icons.check_rounded,
          onTap: () => setState(() => _done = true),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _success() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
          ),
          child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Semantics(header: true, child: Text('Rebate requested!', style: AppTheme.display(22))),
        const SizedBox(height: 4),
        Text('Reference #GC8842', style: AppTheme.body(14, c: AppColors.muted)),
        const SizedBox(height: 16),
        GlassCard(
          tint: AppColors.accent,
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text('New balance: ${DemoUser.commas(_newBalance)} credits',
                textAlign: TextAlign.center,
                style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primaryDark)),
            const SizedBox(height: 4),
            Text('You\'ve offset ~${DemoUser.co2OffsetKg} kg CO₂ so far 🌱',
                textAlign: TextAlign.center,
                style: AppTheme.body(12.5, c: AppColors.primaryDark)),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Done', onTap: () => Navigator.pop(context)),
        const SizedBox(height: 8),
      ],
    );
  }
}
