import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import '../demo_data.dart';

/// "Verified Green Contributor" certificate — shareable social proof and a
/// visual of the green-certification revenue stream.
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Certificate'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    // The certificate card
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFEDF6EE)],
                        ),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 14)),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Seal
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                            ),
                            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
                          ),
                          const SizedBox(height: 14),
                          Text('CERTIFICATE OF',
                              style: AppTheme.body(12, w: FontWeight.w600, c: AppColors.muted)),
                          Text('Green Contribution',
                              textAlign: TextAlign.center,
                              style: AppTheme.display(24, c: AppColors.primaryDark)),
                          const SizedBox(height: 16),
                          Text('This certifies that',
                              style: AppTheme.body(12.5, c: AppColors.muted)),
                          const SizedBox(height: 6),
                          Text(DemoUser.name,
                              textAlign: TextAlign.center, style: AppTheme.display(26)),
                          const SizedBox(height: 6),
                          Text('is a verified Green Contributor in ${DemoUser.ward}',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(13, c: AppColors.charcoal)),
                          const SizedBox(height: 20),

                          // Stats row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _stat('${DemoUser.gci}', 'GCI Score')),
                              _divider(),
                              Expanded(
                                  child: _stat('${DemoUser.treesSurviving}', 'Trees kept')),
                              _divider(),
                              Expanded(
                                  child: _stat('${DemoUser.co2OffsetKg}kg', 'CO₂ offset')),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // QR + verification
                          Row(
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: CustomPaint(painter: _FauxQrPainter()),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Verification code',
                                        style: AppTheme.body(12, c: AppColors.muted)),
                                    Text('GC-2026-7X4821',
                                        style: AppTheme.display(15, c: AppColors.primaryDark)),
                                    const SizedBox(height: 4),
                                    // Honest about the placeholder: the block
                                    // grid beside this is decorative art, not
                                    // an encoded, scannable QR code.
                                    Text('Registry lookup by code. The block pattern is '
                                        'illustrative — scanning is not wired up in this prototype.',
                                        style: AppTheme.body(12, c: AppColors.muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Wrap so the issuer credit drops below the date
                          // instead of overflowing at large text sizes.
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Issued: Jul 2026',
                                  style: AppTheme.body(12, c: AppColors.muted)),
                              // A min-size Row inside a Wrap still receives the
                              // full available width, so the label needs to be
                              // wrappable or it runs past the card edge.
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.verified_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text('GreenCredit Registry',
                                      style: AppTheme.body(12,
                                          w: FontWeight.w600, c: AppColors.primary)),
                                ),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Share certificate',
                      icon: Icons.ios_share_rounded,
                      onTap: () => _toast(context, 'Certificate ready to share'),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      onTap: () => _toast(context, 'Saved to device'),
                      padding: const EdgeInsets.all(15),
                      child: Center(
                        child: Text('Save as image',
                            style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primary)),
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

  Widget _stat(String v, String l) => Semantics(
        label: l,
        value: v,
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(v, style: AppTheme.display(19, c: AppColors.primaryDark)),
              const SizedBox(height: 2),
              Text(l, textAlign: TextAlign.center, style: AppTheme.body(12, c: AppColors.muted)),
            ],
          ),
        ),
      );

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.muted.withValues(alpha: 0.25));

  void _toast(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
}

/// Decorative QR-style block grid (illustrative, not a scannable code).
class _FauxQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.charcoal;
    const n = 7;
    final cell = size.width / n;
    // Deterministic pseudo-pattern (no RNG — stays stable across rebuilds).
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final on = ((x * 3 + y * 5 + x * y) % 4) < 2;
        final finder = (x < 3 && y < 3) || (x > 3 && y < 3) || (x < 3 && y > 3);
        if (on || finder) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * cell + 1, y * cell + 1, cell - 2, cell - 2),
              const Radius.circular(2),
            ),
            p,
          );
        }
      }
    }
    // Finder-square outlines for a QR look.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primary;
    canvas.drawRect(Rect.fromLTWH(1, 1, cell * 3 - 2, cell * 3 - 2), border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
