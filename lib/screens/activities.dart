import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../glass.dart';
import 'capture.dart';

/// How often an action can be claimed. Drives the Weekly / One-time filters.
enum Cadence { weekly, monthly, oneTime }

class _Activity {
  final IconData icon;
  final String title;
  final String reward;
  final String proof;
  final Color color;
  final Cadence cadence;

  /// Peak credits this action can yield, used by the High-value filter.
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

  /// Credits at or above which an action counts as high-value.
  static const _highValueFloor = 100;

  static const _filters = ['All', 'Weekly', 'One-time', 'High-value'];

  static const _acts = [
    _Activity(
      icon: Icons.park_rounded,
      title: 'Plant & maintain a tree',
      reward: 'up to 100 credits',
      proof: 'Geo-photo + check-ins',
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
      icon: Icons.devices_other_rounded,
      title: 'Recycle e-waste',
      reward: '150 credits',
      proof: 'Municipal sign-off',
      color: AppColors.primaryDark,
      cadence: Cadence.oneTime,
      maxCredits: 150,
    ),
    _Activity(
      icon: Icons.compost_rounded,
      title: 'Compost kitchen waste',
      reward: '80 / month',
      proof: 'Photo + peer',
      color: AppColors.primary,
      cadence: Cadence.monthly,
      maxCredits: 80,
    ),
    _Activity(
      icon: Icons.cleaning_services_rounded,
      title: 'Join a cleanliness drive',
      reward: '75 credits',
      proof: 'QR',
      color: AppColors.amber,
      cadence: Cadence.oneTime,
      maxCredits: 75,
    ),
  ];

  List<_Activity> get _visible => switch (_filter) {
        1 => _acts.where((a) => a.cadence == Cadence.weekly).toList(),
        2 => _acts.where((a) => a.cadence == Cadence.oneTime).toList(),
        3 => _acts.where((a) => a.maxCredits >= _highValueFloor).toList(),
        _ => _acts,
      };

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Semantics(header: true, child: Text('Earn Credits', style: AppTheme.display(26))),
        const SizedBox(height: 4),
        Text('Verified actions that count toward your GCI',
            style: AppTheme.body(13.5, c: AppColors.muted)),
        const SizedBox(height: 16),
        SizedBox(
          // Grows with the OS text-size setting so the chips are never clipped.
          height: 38 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Semantics(
              button: true,
              selected: i == _filter,
              label: '${_filters[i]} filter',
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _filter = i),
                  child: GlassChip(label: _filters[i], active: i == _filter),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.filter_alt_off_rounded, color: AppColors.muted, size: 28),
              const SizedBox(height: 10),
              Text('No actions in this category yet',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(14, w: FontWeight.w600, c: AppColors.muted)),
            ]),
          )
        else
          // Keyed on the filter so the entry stagger replays when the visible
          // set changes, instead of reusing the previous rows' elements.
          ...visible
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
    void start() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CaptureScreen()));

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
