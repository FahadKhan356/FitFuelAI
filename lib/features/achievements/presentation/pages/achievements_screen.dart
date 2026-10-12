import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/leaderboard_entry.dart';
import 'package:fitfuel_ai/core/utils/xp_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/achievements_bloc.dart';

const Color _kPurple = Color(AppColors.authPurple);
const Color _kOrange = Color(0xFFFFA24A);
const Color _kCyan = Color(0xFF5BDBF5);

enum _BadgeFilter {
  all('All'),
  unlocked('Unlocked'),
  inProgress('In Progress'),
  locked('Locked');

  const _BadgeFilter(this.label);
  final String label;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementsBloc _bloc;

  /// Anchors the header's "Leaderboard" affordance to the ranking block.
  final GlobalKey _leaderboardKey = GlobalKey();

  /// How many badges the gallery shows before "VIEW ALL" expands it.
  static const int _badgePreviewCount = 9;

  /// The gallery previews the top rows and expands on request.
  bool _showAllBadges = false;

  /// Active filter tab for badges gallery.
  _BadgeFilter _activeFilter = _BadgeFilter.all;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0B0E14) : const Color(0xFFF7F6FB);
  Color get _surface => _isDark ? const Color(0xFF141824) : Colors.white;
  Color get _surfaceAlt =>
      _isDark ? const Color(0xFF1C2235) : const Color(0xFFF0ECFF);
  Color get _textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F2E);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF74717F);
  Color get _border =>
      _isDark ? const Color(0xFF23283E) : const Color(0xFFE6E2EC);

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
    if (target == null) {
      return;
    }
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
    var badges = List<BadgeProgress>.of(summary.badges);

    switch (_activeFilter) {
      case _BadgeFilter.all:
        break;
      case _BadgeFilter.unlocked:
        badges = badges.where((badge) => badge.unlocked).toList();
        break;
      case _BadgeFilter.inProgress:
        badges =
            badges.where((badge) => !badge.unlocked && badge.progress > 0).toList();
        break;
      case _BadgeFilter.locked:
        badges = badges.where((badge) => !badge.unlocked).toList();
        break;
    }

    badges.sort((a, b) {
      if (a.unlocked != b.unlocked) {
        return a.unlocked ? -1 : 1;
      }
      if (a.unlocked) {
        final aAt = a.unlockedAt;
        final bAt = b.unlockedAt;
        if (aAt == null && bAt == null) {
          return 0;
        }
        if (aAt == null) {
          return -1;
        }
        if (bAt == null) {
          return 1;
        }
        return bAt.compareTo(aAt);
      }
      return b.ratio.compareTo(a.ratio);
    });

    if (_activeFilter == _BadgeFilter.all && !_showAllBadges) {
      return badges.take(_badgePreviewCount).toList(growable: false);
    }
    return badges;
  }

  void _showBadgeDetailModal(BadgeProgress badge) {
    HapticFeedback.lightImpact();
    final definition = badge.badge;
    final isDark = _isDark;
    final surfaceColor = _surface;
    final surfaceAltColor = _surfaceAlt;
    final textPrim = _textPrimary;
    final textSec = _textSecondary;
    final borderColor = _border;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: textSec.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: definition.color.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: definition.color.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: definition.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                definition.icon,
                size: 36,
                color: definition.color,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              definition.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrim,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: definition.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    definition.rarity.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: definition.color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceAltColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    definition.category.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSec,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${definition.rarity.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _kPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              definition.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textSec,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceAltColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        badge.unlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_clock_rounded,
                        size: 18,
                        color: badge.unlocked ? Colors.green : definition.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          badge.unlocked
                              ? 'Achievement Unlocked'
                              : 'Progress: ${badge.progress} / ${definition.target}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrim,
                          ),
                        ),
                      ),
                      Text(
                        '${(badge.ratio * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: badge.unlocked ? Colors.green : textSec,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: badge.ratio,
                      backgroundColor: borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        badge.unlocked ? Colors.green : definition.color,
                      ),
                    ),
                  ),
                  if (badge.unlocked && badge.unlockedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Earned on ${DateFormat.yMMMd().format(badge.unlockedAt!)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSec,
                      ),
                    ),
                  ] else if (!badge.unlocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(definition.target - badge.progress).clamp(0, definition.target)} more to unlock',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSec,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<AchievementsBloc, AchievementsState>(
          builder: (context, state) {
            if (state is AchievementsLoading) {
              return Scaffold(
                backgroundColor: _bg,
                body: const SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(color: _kPurple),
                  ),
                ),
              );
            }

            if (state is AchievementsError) {
              return Scaffold(
                backgroundColor: _bg,
                body: SafeArea(
                  child: _ErrorView(
                    message: state.message,
                    onRetry: _load,
                    isDark: _isDark,
                    textPrimary: _textPrimary,
                    textSecondary: _textSecondary,
                  ),
                ),
              );
            }

            final loaded = state is AchievementsLoaded ? state : null;
            final summary = loaded?.summary ?? GamificationSummary.empty;
            final badges = _visibleBadges(summary);
            final inProgressCount = summary.badges
                .where((badge) => !badge.unlocked && badge.progress > 0)
                .length;
            final lockedCount =
                summary.badges.where((badge) => !badge.unlocked).length;

            return Scaffold(
              backgroundColor: _bg,
              body: SafeArea(
                child: RefreshIndicator(
                  color: _kPurple,
                  backgroundColor: _surface,
                  onRefresh: () async => _load(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _IconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              iconColor: _textPrimary,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Achievements',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (loaded != null && loaded.hasRewards) ...[
                          _RewardBanner(
                            xpAwarded: loaded.xpAwarded,
                            badges: loaded.newlyUnlocked,
                            isDark: _isDark,
                            surface: _surface,
                            textPrimary: _textPrimary,
                            textSecondary: _textSecondary,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _RecentAchievementCard(
                          badge: summary.mostRecentUnlocked,
                          isDark: _isDark,
                          surface: _surface,
                          border: _border,
                          textPrimary: _textPrimary,
                          textSecondary: _textSecondary,
                          onTap: _showBadgeDetailModal,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 19,
                              color: _textPrimary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Your Progress',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _scrollToLeaderboard,
                                borderRadius: BorderRadius.circular(999),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Leaderboard',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _kPurple,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 14,
                                        color: _kPurple,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _LevelProgressCard(
                          summary: summary,
                          isDark: _isDark,
                          surface: _surface,
                          textPrimary: _textPrimary,
                          textSecondary: _textSecondary,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.local_fire_department_outlined,
                                iconColor: _kOrange,
                                iconBg: _isDark
                                    ? const Color(0xFF2E2018)
                                    : const Color(0xFFFFF0E4),
                                value: '${summary.streakDays}',
                                label: 'Day Streak',
                                isDark: _isDark,
                                surface: _surface,
                                border: _border,
                                textPrimary: _textPrimary,
                                textSecondary: _textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.trending_up_rounded,
                                iconColor: _kCyan,
                                iconBg: _isDark
                                    ? const Color(0xFF132832)
                                    : const Color(0xFFE8F8FD),
                                value: _formatXp(summary.weeklyXp),
                                label: 'Weekly XP',
                                badge: (loaded?.xpAwarded ?? 0) > 0
                                    ? '+${loaded!.xpAwarded}'
                                    : null,
                                isDark: _isDark,
                                surface: _surface,
                                border: _border,
                                textPrimary: _textPrimary,
                                textSecondary: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              size: 19,
                              color: _kPurple,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Badges Gallery',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${summary.unlockedCount} / ${summary.totalBadgeCount} Unlocked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'All (${summary.totalBadgeCount})',
                                selected: _activeFilter == _BadgeFilter.all,
                                isDark: _isDark,
                                border: _border,
                                textSecondary: _textSecondary,
                                onTap: () => setState(
                                  () => _activeFilter = _BadgeFilter.all,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Unlocked (${summary.unlockedCount})',
                                selected: _activeFilter == _BadgeFilter.unlocked,
                                isDark: _isDark,
                                border: _border,
                                textSecondary: _textSecondary,
                                onTap: () => setState(
                                  () => _activeFilter = _BadgeFilter.unlocked,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'In Progress ($inProgressCount)',
                                selected:
                                    _activeFilter == _BadgeFilter.inProgress,
                                isDark: _isDark,
                                border: _border,
                                textSecondary: _textSecondary,
                                onTap: () => setState(
                                  () => _activeFilter = _BadgeFilter.inProgress,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Locked ($lockedCount)',
                                selected: _activeFilter == _BadgeFilter.locked,
                                isDark: _isDark,
                                border: _border,
                                textSecondary: _textSecondary,
                                onTap: () => setState(
                                  () => _activeFilter = _BadgeFilter.locked,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (badges.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Center(
                              child: Text(
                                'No badges found for this filter.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: badges.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.74,
                            ),
                            itemBuilder: (context, index) => _BadgeCard(
                              badge: badges[index],
                              isDark: _isDark,
                              surface: _surface,
                              border: _border,
                              textPrimary: _textPrimary,
                              textSecondary: _textSecondary,
                              onTap: () =>
                                  _showBadgeDetailModal(badges[index]),
                            ),
                          ),
                        if (_activeFilter == _BadgeFilter.all &&
                            summary.totalBadgeCount > _badgePreviewCount) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => setState(
                              () => _showAllBadges = !_showAllBadges,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color: _isDark
                                    ? const Color(0xFF3B4360)
                                    : const Color(0xFF1F1F2E),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _showAllBadges
                                  ? 'SHOW LESS'
                                  : 'VIEW ALL ${summary.totalBadgeCount} ACHIEVEMENTS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _MilestoneCard(
                          badge: summary.nextMilestone,
                          isDark: _isDark,
                          surface: _surface,
                          border: _border,
                          textPrimary: _textPrimary,
                          textSecondary: _textSecondary,
                          onTap: _showBadgeDetailModal,
                        ),
                        const SizedBox(height: 22),
                        _LeaderboardSection(
                          key: _leaderboardKey,
                          entries: loaded?.leaderboard ??
                              const <LeaderboardEntry>[],
                          scope: loaded?.leaderboardScope ??
                              LeaderboardScope.global,
                          loading: loaded?.leaderboardLoading ?? false,
                          error: loaded?.leaderboardError,
                          isDark: _isDark,
                          surface: _surface,
                          surfaceAlt: _surfaceAlt,
                          border: _border,
                          textPrimary: _textPrimary,
                          textSecondary: _textSecondary,
                          onScopeChanged: (scope) {
                            HapticFeedback.selectionClick();
                            _bloc.add(LoadLeaderboard(scope: scope));
                          },
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
              ),
            );
          },
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.border,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color border;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? _kPurple
                  : (isDark
                      ? const Color(0xFF161B29)
                      : const Color(0xFFEDE9F6)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _kPurple : border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      );
}

class _RecentAchievementCard extends StatelessWidget {
  const _RecentAchievementCard({
    required this.badge,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final BadgeProgress? badge;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<BadgeProgress> onTap;

  @override
  Widget build(BuildContext context) {
    final definition = badge?.badge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: badge == null ? null : () => onTap(badge!),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: definition == null
                      ? (isDark
                          ? const Color(0xFF1E2436)
                          : const Color(0xFFF1F0F5))
                      : definition.color
                          .withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: definition?.color.withValues(alpha: 0.3) ?? border,
                  ),
                ),
                child: Icon(
                  definition?.icon ?? Icons.workspace_premium_outlined,
                  color: definition?.color ?? textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECENT ACHIEVEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      definition?.title ?? 'No badges yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      definition?.description ??
                          'Log meals, drink water or chat with coach to start earning badges.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({
    required this.summary,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  final GamificationSummary summary;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF20173B), Color(0xFF141126)]
                : const [Color(0xFFF8F5FF), Color(0xFFD6C7FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF3F306A) : const Color(0xFFD4C6FF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surface,
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: summary.levelProgress,
                      strokeWidth: 5,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2448)
                          : const Color(0xFFE8DEFF),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_kPurple),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.level}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _kPurple,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kPurple,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LEVEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CURRENT XP',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatXp(summary.xpTotal),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    summary.isMaxLevel
                        ? '• MAX LEVEL'
                        : '/ ${_formatXp(summary.xpTotal + summary.xpToNextLevel)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(summary.levelProgress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: summary.levelProgress,
                backgroundColor: isDark
                    ? const Color(0xFF261F3C)
                    : const Color(0xFFE9E4F6),
                valueColor: const AlwaysStoppedAnimation<Color>(_kPurple),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              summary.isMaxLevel
                  ? 'Top level reached • ${summary.tier} tier'
                  : '${summary.xpToNextLevel} XP to Level ${summary.level + 1} • Keep logging meals!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
}

class _EliteBadge extends StatelessWidget {
  const _EliteBadge({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2045) : const Color(0xFFF0ECFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? const Color(0xFF4C3B78) : const Color(0xFFCABFFF),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _kPurple,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final String? badge;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF251E3D)
                          : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _kPurple,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final BadgeProgress badge;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final definition = badge.badge;
    final unlocked = badge.unlocked;
    final color = definition.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? color.withValues(alpha: 0.3) : border,
              width: unlocked ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: unlocked
                    ? color.withValues(alpha: isDark ? 0.2 : 0.08)
                    : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark
                          ? const Color(0xFF1B2032)
                          : const Color(0xFFF3F3F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  definition.icon,
                  color: unlocked ? color : const Color(0xFF888494),
                  size: 21,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  definition.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? textPrimary : textSecondary,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (unlocked)
                Text(
                  definition.rarity.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3.5,
                      value: badge.ratio,
                      backgroundColor: isDark
                          ? const Color(0xFF262C42)
                          : const Color(0xFFEDEBF2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${badge.progress}/${definition.target}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.badge,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final BadgeProgress? badge;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<BadgeProgress> onTap;

  @override
  Widget build(BuildContext context) {
    final definition = badge?.badge;
    final target = definition?.target;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: badge == null ? null : () => onTap(badge!),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: definition == null
                      ? (isDark
                          ? const Color(0xFF251E3D)
                          : const Color(0xFFF0ECFF))
                      : definition.color
                          .withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  definition?.icon ?? Icons.emoji_events_rounded,
                  color: definition?.color ?? _kPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Milestone',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      definition?.title ?? 'Every badge unlocked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(999)),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: badge?.ratio ?? 1,
                        backgroundColor: isDark
                            ? const Color(0xFF262C42)
                            : const Color(0xFFE8E4EF),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kPurple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                badge == null || target == null
                    ? 'DONE'
                    : '${badge!.progress}/$target',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _kPurple,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner({
    required this.xpAwarded,
    required this.badges,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  final int xpAwarded;
  final List<BadgeProgress> badges;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final titles = badges.map((badge) => badge.badge.title).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF281C45), Color(0xFF1B142F)]
              : const [Color(0xFFF8F5FF), Color(0xFFE4DAFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF493675) : const Color(0xFFD4C6FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: _kPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  xpAwarded > 0
                      ? '+${_formatXp(xpAwarded)} XP earned'
                      : 'New badge unlocked',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badges.isEmpty
                      ? 'Already counted in your level, streak and badges below.'
                      : 'Unlocked $titles.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
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

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({
    required this.entries,
    required this.scope,
    required this.loading,
    required this.onScopeChanged,
    required this.onRetry,
    required this.isDark,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    this.error,
    super.key,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardScope scope;
  final bool loading;
  final String? error;
  final bool isDark;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<LeaderboardScope> onScopeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_outlined, size: 19, color: _kPurple),
              const SizedBox(width: 7),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPurple,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final value in LeaderboardScope.values) ...[
                Expanded(
                  child: _ScopeChip(
                    scope: value,
                    selected: value == scope,
                    isDark: isDark,
                    textSecondary: textSecondary,
                    onTap: () => onScopeChanged(value),
                  ),
                ),
                if (value != LeaderboardScope.values.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          if (scope.isPlaceholder) ...[
            const SizedBox(height: 8),
            Text(
              'Friend rankings ship with social features — showing the all-time board.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (error != null)
            _LeaderboardMessage(
              icon: Icons.cloud_off_rounded,
              message: error!,
              isDark: isDark,
              surface: surface,
              border: border,
              textSecondary: textSecondary,
              onRetry: onRetry,
            )
          else if (entries.isEmpty)
            _LeaderboardMessage(
              icon: Icons.hourglass_empty_rounded,
              message: loading
                  ? 'Loading the ranking…'
                  : 'Nobody is ranked yet — log activity to claim first place.',
              isDark: isDark,
              surface: surface,
              border: border,
              textSecondary: textSecondary,
            )
          else
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 12,
                        endIndent: 12,
                        color: isDark
                            ? const Color(0xFF1E2436)
                            : const Color(0xFFF1EFF6),
                      ),
                    _LeaderboardRow(
                      entry: entries[index],
                      isDark: isDark,
                      surfaceAlt: surfaceAlt,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.scope,
    required this.selected,
    required this.isDark,
    required this.textSecondary,
    required this.onTap,
  });

  final LeaderboardScope scope;
  final bool selected;
  final bool isDark;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? _kPurple
                  : (isDark
                      ? const Color(0xFF1B2032)
                      : const Color(0xFFF2F0F7)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                scope.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isDark,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
  });

  final LeaderboardEntry entry;
  final bool isDark;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isMe;

    return Container(
      color: highlight
          ? (isDark ? const Color(0xFF251E3D) : const Color(0xFFF0ECFF))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 24, child: _RankBadge(rank: entry.rank)),
          const SizedBox(width: 8),
          _Avatar(entry: entry, isDark: isDark, surfaceAlt: surfaceAlt),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kPurple,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Level ${entry.level} • ${entry.tier} • ${entry.streakDays}d streak',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${_formatXp(entry.xp)} XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _kPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => const Color(0xFFE0A82E),
      2 => const Color(0xFF9AA0AE),
      3 => const Color(0xFFC08050),
      _ => const Color(0xFF888494),
    };

    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: rank <= 3 ? 14 : 12.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.entry,
    required this.isDark,
    required this.surfaceAlt,
  });

  final LeaderboardEntry entry;
  final bool isDark;
  final Color surfaceAlt;

  @override
  Widget build(BuildContext context) {
    final url = entry.avatarUrl;
    final initials = Text(
      entry.initials,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: _kPurple,
      ),
    );

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: url == null
          ? initials
          : Image.network(
              url,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initials,
            ),
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  const _LeaderboardMessage({
    required this.icon,
    required this.message,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textSecondary,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textSecondary;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _kPurple,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load your progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

String _formatXp(int value) => NumberFormat.decimalPattern().format(value);
