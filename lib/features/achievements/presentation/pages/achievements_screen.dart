import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

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

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              _RecentAchievementCard(),
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
                  Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _purple,
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
                      children: const [
                        _EliteBadge(),
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
                                '14',
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
                        const Text(
                          '12,450',
                          style: TextStyle(
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
                            '/ 15,000',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '83%',
                          style: TextStyle(
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
                        value: 0.83,
                        backgroundColor: const Color(0xFFE9E4F6),
                        valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2,550 XP to Level 15 • Keep scanning meals!',
                      style: TextStyle(
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
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_outlined,
                      iconColor: _orange,
                      iconBg: Color(0xFFFFF0E4),
                      value: '12',
                      label: 'Day Streak',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: _cyan,
                      iconBg: Color(0xFFE8F8FD),
                      value: '840',
                      label: 'Weekly XP',
                      badge: '+240',
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
                  const Text(
                    '12 / 48 Unlocked',
                    style: TextStyle(
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
                childAspectRatio: 1.05,
                children: const [
                  _BadgeCard(icon: Icons.bolt_rounded, label: 'Early Bird', color: _gold, unlocked: true),
                  _BadgeCard(icon: Icons.center_focus_strong, label: 'Perfect Macro', color: _purple, unlocked: true),
                  _BadgeCard(icon: Icons.workspace_premium_outlined, label: 'Weight Master', color: _orange, unlocked: true),
                  _BadgeCard(icon: Icons.shield_outlined, label: 'Consistent', color: Color(0xFF4A90FF), unlocked: true),
                  _BadgeCard(icon: Icons.fastfood_outlined, label: 'First Scan', color: Color(0xFF16C89A), unlocked: true),
                  _BadgeCard(icon: Icons.star_border_rounded, label: 'AI Expert', color: Color(0xFFFF5B7E), unlocked: true),
                  _BadgeCard(icon: Icons.emoji_events_outlined, label: 'Centurion', color: Color(0xFFB6B6C1), unlocked: false),
                  _BadgeCard(icon: Icons.local_fire_department_outlined, label: 'Month Streak', color: Color(0xFFB6B6C1), unlocked: false),
                  _BadgeCard(icon: Icons.verified_outlined, label: 'Super Coach', color: Color(0xFFB6B6C1), unlocked: false),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: Color(0xFF1F1F2E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'VIEW ALL 48 ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MilestoneCard(),
            ],
          ),
        ),
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

class _RecentAchievementCard extends StatelessWidget {
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF8E8A95), size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT ACHIEVEMENT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hydration Hero',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hit water goals 7 days in a row!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF8C8893)),
          ),
        ],
      ),
    );
  }
}

class _EliteBadge extends StatelessWidget {
  const _EliteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _purpleSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCABFFF)),
      ),
      child: const Text(
        'ELITE RANK',
        style: TextStyle(
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
