import 'package:flutter/material.dart';
import '../theme.dart';
import '../glass.dart';

/// A leaderboard scope — a ward, or a college/society group. Each scope has its
/// own goal and its own board, so switching tabs shows different data.
class _Scope {
  final String label;
  final String goalTitle;
  final String goalMetric;
  final double goalProgress;
  final String goalNote;
  final List<(String, int)> board;
  final String nearbyTitle;
  final String nearbyMeta;

  const _Scope({
    required this.label,
    required this.goalTitle,
    required this.goalMetric,
    required this.goalProgress,
    required this.goalNote,
    required this.board,
    required this.nearbyTitle,
    required this.nearbyMeta,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;

  /// The signed-in citizen, used to highlight their own row.
  static const _me = 'Aditi S.';

  static const _scopes = [
    _Scope(
      label: 'My Ward',
      goalTitle: 'Ward 12 goal',
      goalMetric: '3,200 trees maintained',
      goalProgress: 0.64,
      goalNote: '576 to go before the monsoon target',
      board: [
        ('Rohan M.', 2140),
        (_me, 1240),
        ('Ward 12 RWA', 1105),
        ('Neha K.', 980),
        ('Vikram T.', 870),
      ],
      nearbyTitle: 'Tree planted near Lane 4',
      nearbyMeta: '40m away · 8 min ago',
    ),
    _Scope(
      label: 'College / Society',
      goalTitle: 'MIT Pune — Green Campus',
      goalMetric: '1,500 kg waste segregated',
      goalProgress: 0.41,
      goalNote: '885 kg to go this semester',
      board: [
        ('Eco Club MIT', 3080),
        ('Sanika P.', 1620),
        (_me, 1240),
        ('Hostel B Wing', 1090),
        ('Arjun D.', 640),
      ],
      nearbyTitle: 'Compost bin logged at Hostel B',
      nearbyMeta: 'On campus · 22 min ago',
    ),
  ];

  _Scope get _scope => _scopes[_tab];

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    return ListView(
      // Keyed on the scope so switching tabs resets scroll position and
      // rebuilds the list rather than reusing the previous scope's elements.
      key: ValueKey(_tab),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Semantics(header: true, child: Text('Community', style: AppTheme.display(26))),
        const SizedBox(height: 16),

        // Tabs
        GlassCard(
          padding: const EdgeInsets.all(6),
          radius: 18,
          child: Row(children: [
            for (var i = 0; i < _scopes.length; i++) _tabBtn(_scopes[i].label, i),
          ]),
        ),
        const SizedBox(height: 16),

        // Scope goal
        GlassCard(
          tint: AppColors.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.flag_rounded, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(scope.goalTitle,
                      style: AppTheme.display(15, c: AppColors.primaryDark)),
                ),
              ]),
              const SizedBox(height: 12),
              StatBar(
                label: scope.goalMetric,
                value: scope.goalProgress,
                trailing: '${(scope.goalProgress * 100).round()}%',
              ),
              const SizedBox(height: 6),
              Text(scope.goalNote, style: AppTheme.body(12, c: AppColors.primaryDark)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Semantics(header: true, child: Text('Leaderboard', style: AppTheme.display(16))),
        const SizedBox(height: 12),
        // Rank is derived from list order so it can't disagree with position.
        ...scope.board.indexed.map((entry) {
          final rank = entry.$1 + 1;
          final (name, credits) = entry.$2;
          final isMe = name == _me;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              label: '#$rank ${isMe ? '$name, you' : name}, $credits credits',
              child: ExcludeSemantics(
                child: GlassCard(
                  tint: isMe ? AppColors.primary : Colors.white,
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: Text('#$rank',
                          style: AppTheme.display(15,
                              c: rank <= 3 ? AppColors.primary : AppColors.muted)),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.5),
                      child: Text(name[0], style: AppTheme.display(14, c: AppColors.primaryDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(isMe ? '$name  (You)' : name,
                          style: AppTheme.body(14.5, w: FontWeight.w600)),
                    ),
                    Text('$credits', style: AppTheme.display(15, c: AppColors.primaryDark)),
                    const SizedBox(width: 4),
                    Text('cr', style: AppTheme.body(12, c: AppColors.muted)),
                  ]),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),

        // Peer validation
        Semantics(header: true, child: Text('Peer validation', style: AppTheme.display(16))),
        const SizedBox(height: 4),
        Text('Help verify a neighbour\'s action', style: AppTheme.body(12.5, c: AppColors.muted)),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.photo_camera_back_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scope.nearbyTitle, style: AppTheme.body(14, w: FontWeight.w700)),
                  Text(scope.nearbyMeta, style: AppTheme.body(12, c: AppColors.muted)),
                ],
              ),
            ),
            _pill(Icons.check_rounded, AppColors.primary, 'Confirm this action',
                () => _respond(context, 'Confirmed — thanks for validating')),
            const SizedBox(width: 8),
            _pill(Icons.flag_rounded, AppColors.danger, 'Report this action',
                () => _respond(context, 'Reported for review')),
          ]),
        ),
      ],
    );
  }

  void _respond(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _tabBtn(String label, int i) {
    final active = _tab == i;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
              decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(13.5,
                      w: FontWeight.w700, c: active ? Colors.white : AppColors.muted)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, Color c, String semanticLabel, VoidCallback onTap) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: c, size: 20),
          ),
        ),
      );
}
