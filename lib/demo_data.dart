/// Single source of truth for the prototype's demo figures.
///
/// Screens derive their numbers from here instead of hardcoding them, so the
/// wallet ledger, profile stats, impact totals and redemption sheet cannot
/// drift out of agreement with each other.
library;

import 'package:flutter/material.dart';
import 'theme.dart';

/// A wallet ledger entry. [delta] is signed: positive earns, negative redeems.
class DemoTx {
  final IconData icon;
  final String label;
  final String date;
  final int delta;

  /// Whether this entry came from a verified green action (vs. a redemption).
  bool get isEarn => delta > 0;

  const DemoTx(this.icon, this.label, this.date, this.delta);
}

class DemoUser {
  DemoUser._();

  static const name = 'Aditi Sharma';
  static const shortName = 'Aditi';
  static const ward = 'Ward 12, Pune';

  /// Credits per rupee when redeeming.
  static const creditsPerRupee = 10;

  static const gci = 72;
  static const gciDelta = 6;
  static const treesSurviving = 7;

  /// Cumulative CO2 offset in kg. The one figure every screen quotes.
  static const co2OffsetKg = 182;
  static const waterLitres = 4200;
  static const wasteDivertedKg = 96;

  /// Month the ledger below is scoped to, for "this month" summaries.
  static const currentMonth = 'Jul';

  static const ledger = [
    DemoTx(Icons.park_rounded, 'Tree verified', '12 Jul', 100),
    DemoTx(Icons.qr_code_rounded, 'Waste QR — Ward 12', '10 Jul', 10),
    DemoTx(Icons.bolt_rounded, 'Electricity bill rebate', '05 Jul', -500),
    DemoTx(Icons.compost_rounded, 'Compost logged', '02 Jul', 80),
    DemoTx(Icons.cleaning_services_rounded, 'Cleanliness drive', '28 Jun', 75),
  ];

  /// Current spendable balance.
  static const balance = 1240;

  static Iterable<DemoTx> get _thisMonth =>
      ledger.where((t) => t.date.endsWith(currentMonth));

  /// Credits earned in [currentMonth] — derived, so it always matches the rows
  /// the wallet actually displays.
  static int get earnedThisMonth =>
      _thisMonth.where((t) => t.isEarn).fold(0, (sum, t) => sum + t.delta);

  /// Credits redeemed in [currentMonth], as a negative number.
  static int get redeemedThisMonth =>
      _thisMonth.where((t) => !t.isEarn).fold(0, (sum, t) => sum + t.delta);

  /// Balance carried in from before the visible ledger window.
  static int get _openingBalance =>
      balance - ledger.fold(0, (sum, t) => sum + t.delta);

  /// Lifetime credits earned — higher than [balance], since redemptions have
  /// already been spent out of it. Treats the opening balance as earned, which
  /// holds for this demo account.
  static int get lifetimeEarned =>
      _openingBalance + ledger.where((t) => t.isEarn).fold(0, (sum, t) => sum + t.delta);

  /// Rupee value of the balance.
  static int get balanceInRupees => balance ~/ creditsPerRupee;

  static String rupeesFor(int credits) => '₹${credits ~/ creditsPerRupee}';

  /// 1,240 -> "1,240". Avoids adding an intl dependency for one format.
  static String commas(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String signed(int n) => n > 0 ? '+${commas(n)}' : commas(n);
}

/// A redemption option in the marketplace.
class RedeemOption {
  final IconData icon;
  final String title;
  final int minCredits;
  final bool available;

  const RedeemOption(this.icon, this.title, this.minCredits, {this.available = true});

  /// Title with the layout linebreak removed, for prose contexts.
  String get flatTitle => title.replaceAll('\n', ' ');

  Color get accent => available ? AppColors.primary : AppColors.muted;
}

const demoRedeemOptions = [
  RedeemOption(Icons.bolt_rounded, 'Electricity bill\nrebate', 500),
  RedeemOption(Icons.smartphone_rounded, 'Mobile\nrecharge', 300, available: false),
  RedeemOption(Icons.directions_bus_rounded, 'Bus / Metro\npass discount', 400, available: false),
  RedeemOption(Icons.storefront_rounded, 'Local store\ncoupons', 200),
  RedeemOption(Icons.volunteer_activism_rounded, 'Donate to\ntree project', 100),
  RedeemOption(Icons.card_membership_rounded, 'Tree adoption\ncertificate', 250),
];
