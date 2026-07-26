import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

/// A frosted-glass (glassmorphism) card: blurred backdrop, translucent fill,
/// hairline highlight border, soft shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.blur = 18,
    this.tint = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: 0.55),
                tint.withValues(alpha: 0.28),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
          ),
          child: child,
        ),
      ),
    );

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: card,
    );

    if (onTap == null) return shadowed;
    return Pressable(onTap: onTap!, child: shadowed);
  }
}

/// Wraps a child with a springy scale-down on press for tactile feedback.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Ambient gradient background with soft blurred colour blobs — the depth layer
/// glassmorphism blurs against.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -80, left: -60, child: _blob(220, AppColors.accent.withValues(alpha: 0.55))),
          Positioned(top: 120, right: -90, child: _blob(260, AppColors.primary.withValues(alpha: 0.30))),
          Positioned(bottom: -70, left: -40, child: _blob(240, AppColors.primary.withValues(alpha: 0.22))),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color c) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
      );
}

/// Back button + title row used at the top of every pushed screen.
///
/// Replaces the copy of this Row that each detail screen used to carry, and
/// gives the back button a real hit target and a screen-reader label.
class ScreenHeader extends StatelessWidget {
  final String title;

  /// Optional trailing widget, e.g. a "Mark all read" action.
  final Widget? trailing;

  const ScreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        Semantics(
          button: true,
          label: 'Back',
          child: ExcludeSemantics(
            child: Pressable(
              onTap: () => Navigator.pop(context),
              child: GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.display(20)),
          ),
        ),
        // Flexible so a trailing action shrinks instead of pushing the row past
        // the screen edge once text is scaled up.
        if (trailing != null) ...[const SizedBox(width: 8), Flexible(child: trailing!)],
      ]),
    );
  }
}

/// A pill chip used for tags, filters, metadata.
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final Color? color;
  const GlassChip({super.key, required this.label, this.icon, this.active = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? c : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: active ? c : Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: active ? Colors.white : c),
            const SizedBox(width: 5),
          ],
          // Flexible so a long label wraps instead of overflowing the pill when
          // the OS text size is turned up.
          Flexible(
            child: Text(label,
                style: AppTheme.body(12.5,
                    w: FontWeight.w600, c: active ? Colors.white : AppColors.charcoal)),
          ),
        ],
      ),
    );
  }
}

/// Primary gradient button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;
  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.expand = true});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap ?? () {},
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            // Flexible + wrapping so long labels at large text sizes grow the
            // button's height rather than overflowing its width.
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(15.5, w: FontWeight.w700, c: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular gauge for the Green Contribution Index.
/// Animates the arc sweep and the number count-up on first paint.
class GciGauge extends StatelessWidget {
  final double score; // 0..100
  final double size;
  final String label;

  /// Sweep/count-up duration. Keep the long default for the reveal on Home;
  /// pass something short when the score is driven by a live control, so the
  /// arc tracks the input instead of lagging behind it.
  final Duration duration;

  const GciGauge({
    super.key,
    required this.score,
    this.size = 150,
    this.label = 'Your GCI',
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // The arc and digits are decorative; the Semantics node below carries the
      // score so a screen reader announces it once, as a value.
      //
      // The digits are already sized off the gauge's own geometry, so letting
      // the OS text setting scale them again would overflow this fixed box.
      // noScaling keeps the dial legible; accessibility is served by the
      // Semantics value, not by growing text inside a circle.
      child: MediaQuery.withNoTextScaling(
        child: Semantics(
          label: label,
          value: '${score.round()} out of 100',
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              // No key on this widget: TweenAnimationBuilder animates from
              // whatever value it last showed to the new one, so an updated
              // score eases across rather than restarting from zero.
              tween: Tween(begin: 0, end: score),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _GaugePainter(value / 100),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value.toInt().toString(),
                          style: AppTheme.display(size * 0.26, c: AppColors.primaryDark)),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(size * 0.085,
                              w: FontWeight.w600, c: AppColors.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double t; // 0..1
  _GaugePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final stroke = size.width * 0.09;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.6);

    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [AppColors.accent, AppColors.primary, AppColors.primaryDark],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep * t, false, progress);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.t != t;
}

/// A number that counts up from 0 to [value] on first build.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String suffix;
  final int decimals;
  final double size;
  final Color color;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.decimals = 0,
    this.size = 26,
    this.color = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(decimals)}$suffix',
        style: AppTheme.display(size, c: color),
      ),
    );
  }
}

/// Horizontal labelled progress bar (used in GCI breakdown, ward goals).
class StatBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final String trailing;
  final Color color;
  const StatBar(
      {super.key,
      required this.label,
      required this.value,
      required this.trailing,
      this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: AppTheme.body(13.5, w: FontWeight.w600))),
            const SizedBox(width: 8),
            Text(trailing, style: AppTheme.body(13, w: FontWeight.w700, c: color)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(height: 10, color: Colors.white.withValues(alpha: 0.55)),
              FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
