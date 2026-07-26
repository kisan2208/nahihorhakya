import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';
import 'verification.dart';
import 'fraud_verification.dart';

/// Fraud-resistant in-app camera capture (Screen 5).
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Stack(
        children: [
          // Simulated viewfinder
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF243026), Color(0xFF11170F)],
              ),
            ),
          ),
          const Center(child: Icon(Icons.park_rounded, size: 120, color: Colors.white10)),

          // Framing guide
          Center(
            child: Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          SafeArea(
            // Fills the viewport when there's room, so Spacer keeps the shutter
            // pinned low; scrolls instead of overflowing once large text or a
            // short screen makes the controls taller than the space available.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Semantics(
                      button: true,
                      label: 'Close camera',
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pop(context),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.close_rounded, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text('Plant a Tree',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.display(16, c: Colors.white)),
                    ),
                    // Balances the close button so the title stays centred.
                    const SizedBox(width: 40),
                  ]),
                ),
                const SizedBox(height: 8),
                // Metadata chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _MetaChip(icon: Icons.location_on_rounded, label: 'GPS captured'),
                    _MetaChip(icon: Icons.schedule_rounded, label: 'Timestamp auto'),
                    _MetaChip(icon: Icons.lock_rounded, label: 'In-app photo only'),
                  ],
                ),
                const Spacer(),
                // Helper + info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Stand next to your sapling so we can verify location.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(13.5, c: Colors.white70),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _explainCapture(context),
                  child: Text('Why we need this',
                      style: AppTheme.body(12.5, w: FontWeight.w600, c: AppColors.accent)),
                ),
                const SizedBox(height: 12),
                // Shutter row: gallery-upload (fraud demo) | live capture | spacer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery upload — the suspicious path (no live capture).
                    Semantics(
                      button: true,
                      label: 'Upload from gallery. Not permitted — will fail verification',
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _tryGalleryUpload(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(color: Colors.white38),
                                ),
                                child: const Icon(Icons.photo_library_rounded,
                                    color: Colors.white70, size: 24),
                              ),
                              const SizedBox(height: 4),
                              Text('Upload', style: AppTheme.body(12, c: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Live shutter — the genuine path.
                    Semantics(
                      button: true,
                      label: 'Capture photo',
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const VerificationScreen())),
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Balances the upload button so the shutter stays centred.
                    const SizedBox(width: 52),
                  ],
                ),
                const SizedBox(height: 28),
              ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Explains what the capture collects and why — the consent surface the
  /// DPDP-aware terms promise.
  void _explainCapture(BuildContext context) {
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Why we need this', style: AppTheme.display(20)),
                  ),
                  const SizedBox(height: 14),
                  _why(Icons.location_on_rounded, 'Location',
                      'Confirms the action happened where you say it did, and lets us weight it against your ward\'s priorities.'),
                  _why(Icons.schedule_rounded, 'Timestamp',
                      'Proves the photo is fresh, and anchors the check-in schedule that keeps tree credits alive.'),
                  _why(Icons.lock_rounded, 'In-app capture only',
                      'Gallery uploads can be re-used, downloaded or AI-generated. Capturing live is what makes the credit trustworthy.'),
                  _why(Icons.shield_moon_rounded, 'What we don\'t do',
                      'Photos are used for verification only. Sponsors see aggregated impact, never your identity without consent.'),
                  const SizedBox(height: 4),
                  PrimaryButton(label: 'Got it', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _why(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTheme.body(13.5, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(body, style: AppTheme.body(12.5, c: AppColors.muted)),
            ]),
          ),
        ]),
      );

  /// Demonstrates the fraud path: gallery uploads are discouraged, and when
  /// forced through, the verification engine rejects the un-stamped image.
  void _tryGalleryUpload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery upload disabled — running fraud check on this image.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1400),
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FraudVerificationScreen()));
    });
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 5),
        // Wraps rather than overflowing the pill at large text sizes.
        Flexible(
          child: Text(label, style: AppTheme.body(12, w: FontWeight.w600, c: Colors.white)),
        ),
      ]),
    );
  }
}
