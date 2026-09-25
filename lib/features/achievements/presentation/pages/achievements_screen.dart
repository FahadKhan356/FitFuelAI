import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/leaderboard_entry.dart';
import 'package:fitfuel_ai/core/utils/xp_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/achievements_bloc.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleSoft = Color(0xFFF0ECFF);
const _purpleTint = Color(0xFFEAE2FF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF74717F);
const _border = Color(0xFFE6E2EC);
const _gold = Color(0xFFF2B84B);
const _cyan = Color(0xFF5BDBF5);
const _orange = Color(0xFFFFA24A);

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementsBloc _bloc;

  /// Anchors the header's "Leaderboard" affordance to the ranking block further
  /// down the same page: one sync feeds both halves.
  final GlobalKey _leaderboardKey = GlobalKey();

  /// How many badges the gallery shows before "VIEW ALL" expands it.
  static const int _badgePreviewCount = 9;

  /// The gallery previews the top rows and expands on request.
  bool _showAllBadges = false;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AchievementsBloc>();
    _load();
  }

  /// `sync` is idempotent — the ledger dedupes per day and one-off awards are
  /// filtered against what is already stored — so re-running it on retry is
  /// safe and never double-credits.
  void _load() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _bloc.add(LoadGamification(userId));
    }
  }

  void _scrollToLeaderboard() {
    final target = _leaderboardKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  /// Unlocked badges first (most recent first), then the locked ones closest to
  /// unlocking, so the preview grid always shows the rows that matter.
  List<BadgeProgress> _visibleBadges(GamificationSummary summary) {
    final badges = List<BadgeProgress>.of(summary.badges);
    badges.sort((a, b) {
      if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
      if (a.unlocked) {
        final aAt = a.unlockedAt;
        final bAt = b.unlockedAt;
        if (aAt == null && bAt == null) return 0;
        // A null timestamp means "earned by this run", i.e. the newest.
        if (aAt == null) return -1;
        if (bAt == null) return 1;
        return bAt.compareTo(aAt);
      }
      return b.ratio.compareTo(a.ratio);
    });
    return _showAllBadges
        ? badges
        : badges.take(_badgePreviewCount).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AchievementsBloc, AchievementsState>(
        builder: (context, state) {
          if (state is AchievementsLoading) {
            return const Scaffold(
              backgroundColor: _bg,
              body: SafeArea(
                child: Center(child: CircularProgressIndicator(color: _purple)),
              ),
            );
          }

          if (state is AchievementsError) {
            return Scaffold(
              backgroundColor: _bg,
              body: SafeArea(
                child: _ErrorView(message: state.message, onRetry: _load),
              ),
            );
          }

          // Anything not loaded yet renders from the empty summary, so the page
          // explains how badges are earned instead of showing invented numbers.
          final loaded = state is AchievementsLoaded ? state : null;
          final summary = loaded?.summary ?? GamificationSummary.empty;
          final badges = _visibleBadges(summary);

          return Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _IconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Achievements',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (loaded != null && loaded.hasRewards) ...[
                      _RewardBanner(
                        xpAwarded: loaded.xpAwarded,
                        badges: loaded.newlyUnlocked,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _RecentAchievementCard(badge: summary.mostRecentUnlocked),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 19, color: _textPrimary),
                            const SizedBox(width: 7),
                            Text(
                              'Your Progress',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Scrolls to the ranking block instead of pushing a
                        // route: both halves come from the same sync.
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _scrollToLeaderboard,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Leaderboard',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _purple,
                                        ),
                                  ),
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 15,
                                    color: _purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF8F5FF), Color(0xFFD6C7FF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD4C6FF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _EliteBadge(
                                label: '${summary.tier.toUpperCase()} RANK',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _purple.withValues(alpha: 0.16),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _purpleTint, width: 5),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${summary.level}',
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: _purple,
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _purple,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'LEVEL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CURRENT XP',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatXp(summary.xpTotal),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  summary.isMaxLevel
                                      ? '• MAX LEVEL'
                                      : '/ ${_formatXp(summary.xpTotal + summary.xpToNextLevel)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 15,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(summary.levelProgress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: summary.levelProgress,
                              backgroundColor: const Color(0xFFE9E4F6),
                              valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.isMaxLevel
                                ? 'Top level reached • ${summary.tier} tier'
                                : '${summary.xpToNextLevel} XP to Level ${summary.level + 1} • Keep logging meals!',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department_outlined,
                            iconColor: _orange,
                            iconBg: const Color(0xFFFFF0E4),
                            value: '${summary.streakDays}',
                            label: 'Day Streak',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.trending_up_rounded,
                            iconColor: _cyan,
                            iconBg: const Color(0xFFE8F8FD),
                            value: _formatXp(summary.weeklyXp),
                            label: 'Weekly XP',
                            // Only shown when this sync actually wrote XP, so
                            // the chip always matches the ledger.
                            badge: (loaded?.xpAwarded ?? 0) > 0
                                ? '+${loaded!.xpAwarded}'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_outlined, size: 19, color: _purple),
                            const SizedBox(width: 7),
                            Text(
                              'Badges Gallery',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${summary.unlockedCount} / ${summary.totalBadgeCount} Unlocked',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                      children: badges
                          .map((badge) => _BadgeCard(badge: badge))
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: summary.totalBadgeCount > _badgePreviewCount
                          ? () => setState(() => _showAllBadges = !_showAllBadges)
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: Color(0xFF1F1F2E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _showAllBadges
                            ? 'SHOW LESS'
                            : 'VIEW ALL ${summary.totalBadgeCount} ACHIEVEMENTS',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MilestoneCard(badge: summary.nextMilestone),
                    const SizedBox(height: 24),
                    // The same sync that resolved the badges above also
                    // delivered the ranking, so it renders on this page.
                    _LeaderboardSection(
                      key: _leaderboardKey,
                      entries: loaded?.leaderboard ?? const <LeaderboardEntry>[],
                      scope: loaded?.leaderboardScope ?? LeaderboardScope.global,
                      loading: loaded?.leaderboardLoading ?? false,
                      error: loaded?.leaderboardError,
                      onScopeChanged: (scope) =>
                          _bloc.add(LoadLeaderboard(scope: scope)),
                      onRetry: () => _bloc.add(
                        LoadLeaderboard(
                          scope: loaded?.leaderboardScope ??
                              LeaderboardScope.global,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: _textPrimary),
        ),
      ),
    );
  }
}

/// The newest badge the user actually owns, or a prompt to start earning one.
class _RecentAchievementCard extends StatelessWidget {
  const _RecentAchievementCard({required this.badge});

  final BadgeProgress? badge;

  @override
  Widget build(BuildContext context) {
    final definition = badge?.badge;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: definition == null
                  ? Colors.white
                  : definition.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              definition?.icon ?? Icons.workspace_premium_outlined,
              color: definition?.color ?? const Color(0xFF8E8A95),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENT ACHIEVEMENT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  definition?.title ?? 'No badges yet',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  definition?.description ??
                      'Log a meal, hit your water goal or chat with your coach to start earning badges.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteBadge extends StatelessWidget {
  const _EliteBadge({required this.label});

  /// Tier label straight from the level system, e.g. "GOLD RANK".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _purpleSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCABFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: _purple,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.unlocked,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.18) : _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked ? color.withValues(alpha: 0.12) : const Color(0xFFF3F3F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? color : const Color(0xFFB8B5C0),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: unlocked ? _textPrimary : const Color(0xFFAEAAB5),
              ),
            ),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 6),
            const Icon(Icons.lock_outline, size: 14, color: Color(0xFFC1BDC8)),
          ],
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _purpleSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_border_rounded, color: _purple, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Milestone',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '15-Day Scan Streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: 0.83,
                    backgroundColor: Color(0xFFE8E4EF),
                    valueColor: AlwaysStoppedAnimation<Color>(_purple),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '12/15',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }
}
