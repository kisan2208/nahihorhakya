import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/onboarding.dart';

void main() => runApp(const GreenCreditApp());

class GreenCreditApp extends StatelessWidget {
  const GreenCreditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenCredit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Allow the OS text-size setting through up to 2x. Screens use scrollable
      // bodies so large text extends the scroll extent instead of overflowing.
      // The floor stays at 1.0 — shrinking text below the design size only
      // hurts legibility.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0),
          ),
          child: child!,
        );
      },
      home: const OnboardingScreen(),
    );
  }
}
