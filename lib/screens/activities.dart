import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../glass.dart';
import 'authentic_capture_screen.dart';
import 'ewaste_recycle_screen.dart';

/// Cadence filtering.
enum Cadence { weekly, monthly, oneTime }

class _Activity {
  final IconData icon;
  final String title;
  final String reward;
  final String proof;
  final Color color;
  final Cadence cadence;
  final int maxCredits;

  const _Activity({
    required this.icon,
    required this.title,
    required this.reward,
    required this.proof,
    required this.color,
    required this.cadence,
    required this.maxCredits,
  });
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  int _filter = 0;

  static const _highValueFloor = 100;
  static const _filters = ['All', 'Weekly', 'One-time', 'High-value'];

  static const _acts = [
    _Activity(
      icon: Icons.park_rounded,
      title: 'Plant & maintain a tree',
      reward: 'up to 100 credits',
      proof: 'Geo-photo + 30m check',
      color: AppColors.primary,
      cadence: Cadence.oneTime,
      maxCredits: 100,
    ),
    _Activity(
      icon: Icons.delete_sweep_rounded,
      title: 'Segregate household waste',
      reward: '10 / week',
      proof: 'QR at drive',
      color: AppColors.amber,
      cadence: Cadence.weekly,
      maxCredits: 10,
    ),
    _Activity(
      icon: Icons.recycling_rounded,
      title: 'Recycle e-waste',
      reward: '150 credits',
      proof: '2 Photos: Before & After',
      color: AppColors.primaryDark,
      cadence: Cadence.oneTime,
      maxCredits: 150,
    ),
    _Activity(
      icon: Icons.compost_rounded,
      title: 'Compost kitchen waste',
      reward: '80 / month',
      proof: 'Photo + peer',
      color: Color(0xFF795548),
      cadence: Cadence.monthly,
      maxCredits: 80,
    ),
    _Activity(
      icon: Icons.cleaning_services_rounded,
      title: 'Join a cleanliness drive',
      reward: '75 credits',
      proof: 'Beach drive + 30m check',
      color: Color(0xFF0288D1),
      cadence: Cadence.oneTime,
      maxCredits: 75,
    ),
  ];

  Iterable<_Activity> get _visibleActs {
    switch (_filter) {
      case 1:
        return _acts.where((a) => a.cadence == Cadence.weekly);
      case 2:
        return _acts.where((a) => a.cadence == Cadence.oneTime);
      case 3:
        return _acts.where((a) => a.maxCredits >= _highValueFloor);
      default:
        return _acts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Semantics(header: true, child: Text('Earn Credits', style: AppTheme.display(24))),
        const SizedBox(height: 2),
        Text('Verified actions that count toward your GCI',
            style: AppTheme.body(13, c: AppColors.muted)),
        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_filters.length, (i) {
              final selected = i == _filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_filters[i]),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  labelStyle: AppTheme.body(12.5,
                      w: selected ? FontWeight.w700 : FontWeight.w500,
                      c: selected ? Colors.white : AppColors.charcoal),
                  side: BorderSide(
                      color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.8)),
                  onSelected: (_) => setState(() => _filter = i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

        // Activity cards
        ..._visibleActs
            .map((a) => Padding(
                  key: ValueKey('${_filter}_${a.title}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _card(a),
                ))
            .toList()
            .animate(interval: 70.ms)
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .slideX(begin: 0.12, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _card(_Activity a) {
    void start() {
      if (a.title == 'Recycle e-waste') {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EWasteRecycleScreen()));
      } else {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AuthenticCaptureScreen()));
      }
    }

    return Semantics(
      button: true,
      label: '${a.title}, ${a.reward}, verified by ${a.proof}',
      child: ExcludeSemantics(
        child: GlassCard(
          onTap: start,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15)),
              child: Icon(a.icon, color: a.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: AppTheme.body(15, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(a.reward, style: AppTheme.body(13, w: FontWeight.w600, c: a.color)),
                  const SizedBox(height: 8),
                  GlassChip(label: a.proof, icon: Icons.verified_user_rounded),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}
