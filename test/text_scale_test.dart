import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greencredit/theme.dart';
import 'package:greencredit/glass.dart';
import 'package:greencredit/shell.dart';
import 'package:greencredit/screens/about.dart';
import 'package:greencredit/screens/capture.dart';
import 'package:greencredit/screens/certificate.dart';
import 'package:greencredit/screens/gci_detail.dart';
import 'package:greencredit/screens/gci_simulator.dart';
import 'package:greencredit/screens/impact.dart';
import 'package:greencredit/screens/notifications.dart';
import 'package:greencredit/screens/redeem.dart';
import 'package:greencredit/screens/terms.dart';
import 'package:greencredit/screens/verification.dart';
import 'package:greencredit/screens/fraud_verification.dart';
import 'package:greencredit/screens/onboarding.dart';

/// The app raises the OS text-scale cap to 2x, so every screen has to survive
/// large text without a layout overflow. These tests pump each screen at 2x on
/// a small phone and fail on any rendering exception (overflow included).
void main() {
  final screens = <String, Widget>{
    // HomeShell builds all five tabs eagerly via IndexedStack, so this one
    // entry exercises home, activities, wallet, community and profile.
    'shell': const HomeShell(),
    'onboarding': const OnboardingScreen(),
    'about': const AboutScreen(),
    'capture': const CaptureScreen(),
    'certificate': const CertificateScreen(),
    'gci detail': const GciDetailScreen(),
    'gci simulator': const GciSimulatorScreen(),
    'impact': const ImpactScreen(),
    'notifications': const NotificationsScreen(),
    'redeem': const RedeemScreen(),
    'terms': const TermsScreen(),
    'verification': const VerificationScreen(),
    'fraud verification': const FraudVerificationScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} survives 2x text on a small screen', (tester) async {
      // iPhone SE-class logical size — the tightest target worth supporting.
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
            ),
            child: child!,
          ),
          home: AmbientBackground(child: entry.value),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${entry.key} overflowed at 2x text');
    });
  }
}
