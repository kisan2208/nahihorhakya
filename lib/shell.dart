import 'package:flutter/material.dart';
import 'theme.dart';
import 'glass.dart';
import 'screens/home.dart';
import 'screens/activities.dart';
import 'screens/wallet.dart';
import 'screens/community.dart';
import 'screens/profile.dart';

/// Identifies the floating nav bar so tests can assert on its measured size.
const navBarKey = Key('bottom-nav-bar');

/// The main navigable shell after onboarding — holds the 5 tabs and the
/// frosted floating bottom navigation bar.
///
/// Lives outside main.dart so screens can navigate here without importing the
/// app entrypoint back (which made main <-> onboarding a cycle).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _tabs = const [
    HomeScreen(),
    ActivitiesScreen(),
    WalletScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    (Icons.eco_rounded, 'Home'),
    (Icons.task_alt_rounded, 'Activities'),
    (Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.groups_rounded, 'Community'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          // IndexedStack keeps every tab mounted and shows one — no
          // transition-time double layout, so no red error/overflow flash.
          // TickerMode then freezes the animations of the tabs that aren't
          // visible, so their entry staggers actually play on first view
          // instead of having silently finished at app launch.
          child: IndexedStack(
            index: _index,
            children: List.generate(
              _tabs.length,
              (i) => TickerMode(enabled: i == _index, child: _tabs[i]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: GlassCard(
          key: navBarKey,
          radius: 32,
          blur: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == _index;
              final (icon, label) = _items[i];
              // Icon-only nav. Active icon sits in a raised gradient pill.
              // Expanded (not a fixed 52px) so five items can never overflow
              // the bar on a narrow device.
              return Expanded(
                child: Semantics(
                  label: label,
                  button: true,
                  selected: active,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _index = i),
                    // heightFactor: 1 is essential — a bare Center expands to
                    // the tallest constraint it is offered, which here is the
                    // whole viewport, stretching the nav bar over the screen.
                    // Width stays unfactored so the full column is tappable.
                    child: Center(
                      heightFactor: 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: active ? 26 : 24,
                          color: active ? Colors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
