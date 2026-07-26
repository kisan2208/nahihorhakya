import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'glass.dart';

/// One layer of the multi-layer authenticity check.
class VerificationStep {
  final String label;

  /// Whether this layer cleared. A single failed layer fails the submission.
  final bool passed;

  /// Shown under the label once the layer has run. Used to explain a failure.
  final String? detail;

  const VerificationStep(this.label, {this.passed = true, this.detail});
}

/// Runs a staged authenticity check, then hands off to [resultBuilder].
///
/// Shared by the genuine-capture and fraud-attempt screens so the stepper
/// behaviour and timing stay identical between them — only the step outcomes
/// and the result panel differ.
///
/// NOTE: the outcomes are scripted for the prototype. No EXIF, GPS, AI-image
/// or duplicate detection runs on device; each layer is a timed placeholder
/// standing in for a server-side check.
class VerificationFlow extends StatefulWidget {
  final List<VerificationStep> steps;
  final String progressTitle;
  final String progressSubtitle;

  /// Colours the in-flight spinner and the active-step ring.
  final Color accent;

  /// Tint of the glass card holding the spinner.
  final Color accentTint;

  final Widget Function(BuildContext context, bool allPassed) resultBuilder;

  const VerificationFlow({
    super.key,
    required this.steps,
    required this.progressTitle,
    required this.progressSubtitle,
    required this.resultBuilder,
    this.accent = AppColors.primaryDark,
    this.accentTint = AppColors.accent,
  });

  @override
  State<VerificationFlow> createState() => _VerificationFlowState();
}

class _VerificationFlowState extends State<VerificationFlow> {
  int _step = 0;
  bool _done = false;

  static const _perStep = Duration(milliseconds: 850);
  static const _beforeResult = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < widget.steps.length; i++) {
      await Future.delayed(_perStep);
      if (!mounted) return;
      setState(() => _step = i + 1);
    }
    await Future.delayed(_beforeResult);
    if (mounted) setState(() => _done = true);
  }

  bool get _allPassed => widget.steps.every((s) => s.passed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _done ? widget.resultBuilder(context, _allPassed) : _progress(),
          ),
        ),
      ),
    );
  }

  Widget _progress() {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: GlassCard(
            radius: 40,
            padding: const EdgeInsets.all(28),
            tint: widget.accentTint,
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(widget.accent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(widget.progressTitle, textAlign: TextAlign.center, style: AppTheme.display(22)),
        const SizedBox(height: 6),
        Text(widget.progressSubtitle,
            textAlign: TextAlign.center, style: AppTheme.body(14, c: AppColors.muted)),
        const SizedBox(height: 28),
        GlassCard(
          child: Column(
            children: List.generate(widget.steps.length, (i) {
              final s = widget.steps[i];
              final checked = i < _step;
              final active = i == _step;
              final failed = checked && !s.passed;
              return Semantics(
                label: s.label,
                value: checked
                    ? (s.passed ? 'Passed' : 'Failed${s.detail == null ? '' : ' — ${s.detail}'}')
                    : active
                        ? 'Checking'
                        : 'Waiting',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked
                            ? (failed ? AppColors.danger : AppColors.primary)
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                            color: active ? widget.accent : Colors.transparent, width: 2),
                      ),
                      child: checked
                          ? Icon(failed ? Icons.close_rounded : Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : active
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(widget.accent)),
                                )
                              : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label,
                              style: AppTheme.body(14,
                                  w: checked || active ? FontWeight.w700 : FontWeight.w500,
                                  c: checked || active ? AppColors.charcoal : AppColors.muted)),
                          if (checked && s.detail != null)
                            Text(s.detail!,
                                style: AppTheme.body(12,
                                    c: failed ? AppColors.danger : AppColors.muted)),
                        ],
                      ),
                    ),
                    if (checked)
                      ExcludeSemantics(
                        child: Icon(
                          failed ? Icons.cancel_rounded : Icons.check_circle_rounded,
                          size: 18,
                          color: failed ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Shared result layout: badge, headline, detail panel, and actions.
class VerificationResult extends StatelessWidget {
  final IconData icon;
  final List<Color> badgeGradient;
  final Color glowColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Widget panel;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final bool shake;

  const VerificationResult({
    super.key,
    required this.icon,
    required this.badgeGradient,
    required this.glowColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.panel,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.shake = false,
  });

  @override
  Widget build(BuildContext context) {
    var badge = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: badgeGradient),
        boxShadow: [
          BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Icon(icon, size: 64, color: Colors.white),
    )
        .animate()
        .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: shake ? 550.ms : 600.ms,
            curve: shake ? Curves.easeOutBack : Curves.elasticOut)
        .fadeIn(duration: 300.ms);
    if (shake) badge = badge.animate().shake(hz: 3, curve: Curves.easeInOut);

    // Scrolls rather than overflowing when text is scaled up or the screen
    // is short; still centres when there is room to spare.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            children: [
              const SizedBox(height: 24),
              badge,
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(title, textAlign: TextAlign.center, style: AppTheme.display(28))
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              ),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center, style: AppTheme.display(20, c: subtitleColor)),
              const SizedBox(height: 20),
              panel,
              const SizedBox(height: 28),
              PrimaryButton(label: primaryLabel, icon: primaryIcon, onTap: onPrimary),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(13.5, w: FontWeight.w600, c: AppColors.muted)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "this is scripted, not a live model" disclosure. Keeps the prototype
/// honest wherever it shows a confidence number.
class SimulatedNotice extends StatelessWidget {
  final String message;
  const SimulatedNotice({super.key, this.message = 'Simulated result — prototype demo'});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.science_outlined, size: 15, color: AppColors.muted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message, style: AppTheme.body(12, w: FontWeight.w600, c: AppColors.muted)),
      ),
    ]);
  }
}
