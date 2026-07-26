import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greencredit/main.dart';
import 'package:greencredit/shell.dart';

void main() {
  testWidgets('App boots to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const GreenCreditApp());
    // Onboarding entry animations use flutter_animate delays, which schedule
    // timers. Settle them so none outlive the widget tree.
    await tester.pumpAndSettle();
    expect(find.text('GreenCredit'), findsWidgets);
  });

  testWidgets('Get Started enters the tab shell', (WidgetTester tester) async {
    await tester.pumpWidget(const GreenCreditApp());
    await tester.pumpAndSettle();

    // Advance through the onboarding slides.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('Bottom nav switches the visible tab', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Aditi 👋'), findsOneWidget);
    expect(find.text('Recent activity'), findsNothing);

    // IndexedStack marks unselected tabs offstage, and finders skip offstage
    // widgets by default — so these assertions track what is actually visible.
    await tester.tap(find.byIcon(Icons.account_balance_wallet_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Hi, Aditi 👋'), findsNothing);
  });

  testWidgets('Bottom nav bar stays a bar, not a full-screen panel',
      (WidgetTester tester) async {
    // Regression: a bare Center around each nav icon expanded to the tallest
    // offered constraint (the whole viewport), stretching the frosted nav card
    // over the entire screen and blurring the content behind it.
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    // 52px icon + 12px vertical padding top and bottom = 76px.
    final navBar = tester.getSize(find.byKey(navBarKey));
    expect(navBar.height, lessThan(120),
        reason: 'nav bar should hug its icons, not fill the viewport');
  });

  testWidgets('Bottom nav items carry semantic labels', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Activities', 'Wallet', 'Community', 'Profile']) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: '$label nav item');
    }
    handle.dispose();
  });
}
