import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../glass.dart';
import '../shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    (Icons.park_rounded, 'Do good.\nGet rewarded.',
        'Turn everyday green actions into real, verifiable value.'),
    (Icons.workspace_premium_rounded, 'Every verified action\nearns Green Credits',
        'Plant a tree, segregate waste, join a drive — we verify it, you earn.'),
    (Icons.receipt_long_rounded, 'Redeem for your\nbill & recharge',
        'Cash in credits against electricity bills, mobile recharge and more.'),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    // Expanded rather than Spacer: at large text sizes the
                    // wordmark shrinks to fit instead of shoving "Log in" off
                    // the edge of the screen.
                    Expanded(
                      child: Text('GreenCredit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.display(20)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeShell())),
                      child: Text('Log in',
                          maxLines: 1,
                          style: AppTheme.body(14, w: FontWeight.w600, c: AppColors.primary)),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) {
                      final s = _slides[i];
                      // Center when there's room; scroll when the screen is
                      // short or fonts are large. Never overflows.
                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              key: ValueKey(i),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GlassCard(
                                  radius: 40,
                                  padding: const EdgeInsets.all(40),
                                  tint: AppColors.accent,
                                  child: Icon(s.$1, size: 88, color: AppColors.primaryDark),
                                )
                                    .animate()
                                    .scale(
                                        begin: const Offset(0.7, 0.7),
                                        end: const Offset(1, 1),
                                        duration: 520.ms,
                                        curve: Curves.easeOutBack)
                                    .fadeIn(duration: 420.ms),
                                const SizedBox(height: 40),
                                Text(s.$2, textAlign: TextAlign.center, style: AppTheme.display(28))
                                    .animate()
                                    .fadeIn(delay: 180.ms, duration: 420.ms)
                                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                                const SizedBox(height: 16),
                                Text(s.$3,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.body(15, c: AppColors.muted))
                                    .animate()
                                    .fadeIn(delay: 320.ms, duration: 420.ms)
                                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
