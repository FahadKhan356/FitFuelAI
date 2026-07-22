import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _bg = Color(0xFFF5F5FA);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleLight = Color(AppColors.authPurpleBg);
const _purpleSoft = Color(0xFFEAE6FF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF6F6F7C);
const _border = Color(0xFFE6E4EE);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
                child: Row(
                  children: [
                    Text(
                      'Profile',
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _TopIconButton(
                      icon: Icons.workspace_premium_outlined,
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    const SizedBox(width: 6),
                    _TopIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFEDEAF3)),
              const SizedBox(height: 30),
              const Center(
                child: Column(
                  children: [
                    _AvatarWithBadge(),
                    SizedBox(height: 18),
                    Text(
                      'Alex Johnson',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Level 14 Fitness Enthusiast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    _PremiumPill(),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.local_fire_department_outlined,
                        iconBackground: Color(0xFFFFF0DE),
                        iconColor: Color(0xFFF4A340),
                        label: 'STREAK',
                        value: '12 Days',
                        subtitle: 'Keep it up, Alex!',
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.trending_down_rounded,
                        iconBackground: Color(0xFFE1F8E9),
                        iconColor: Color(0xFF44B97A),
                        label: 'WEIGHT\nLOST',
                        value: '4.2 kg',
                        subtitle: 'Since Jan 2024',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 21,
                      color: _textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Achievements',
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View All',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Expanded(
                      child: _AchievementItem(
                        icon: Icons.bolt_rounded,
                        label: 'Early Riser',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AchievementItem(
                        icon: Icons.water_drop_outlined,
                        label: 'H2O Master',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AchievementItem(
                        icon: Icons.center_focus_strong,
                        label: 'Macro King',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GoalsCard(textTheme: textTheme),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ACCOUNT SETTINGS',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: const Color(0xFF77757E),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: const [
                    _SettingTile(
                      icon: Icons.shield_outlined,
                      title: 'Personal Information',
                    ),
                    SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Premium Subscription',
                      trailingText: 'Active',
                    ),
                    SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      trailingText: 'Daily Reminders',
                    ),
                    SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.adjust_outlined,
                      title: 'Health Goals',
                      trailingText: 'Weight Loss',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFF0C6C6)),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Logout Account',
                    style: TextStyle(
                      color: Color(0xFFCB6670),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'NutriLens AI v2.4.0 • Crafted for Health',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8B8797),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
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
          width: 38,
          height: 38,
          child: Icon(icon, size: 24, color: const Color(0xFF4C4A59)),
        ),
      ),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  const _PremiumPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8D3F7)),
      ),
      child: const Text(
        'Premium Member',
        style: TextStyle(
          color: _purple,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/onBoarding_Hero_Image.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(
                    color: const Color(0x2AFFFFFF),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 6,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF5B4EE8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4EE8).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E6EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF7C7580),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1F2E),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF777580),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: _purpleSoft,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC9C1F2), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4EE8).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5B4EE8),
            size: 29,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2934),
          ),
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.textTheme,
  });

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Goals",
            style: textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF242333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're 75% through your daily targets!",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              color: const Color(0xFF7C798A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const _GoalRow(
            icon: Icons.bolt_rounded,
            iconColor: Color(0xFF5B4EE8),
            label: 'Calories',
            progress: 0.75,
            value: '1650 / 2200',
          ),
          const SizedBox(height: 12),
          const _GoalRow(
            icon: Icons.water_drop_outlined,
            iconColor: Color(0xFF52C7D8),
            label: 'Water Intake',
            progress: 0.70,
            value: '2100 / 3000',
          ),
          const SizedBox(height: 12),
          const _GoalRow(
            icon: Icons.adjust_outlined,
            iconColor: Color(0xFF8B4DE8),
            label: 'Protein',
            progress: 0.76,
            value: '92 / 120',
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.progress,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double progress;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2940),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6F6C7D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: const Color(0xFFE7E1FF),
            valueColor: const AlwaysStoppedAnimation<Color>(_purple),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F4FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6C6674)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF22212E),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B7786),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFFC5C2CC)),
          ],
        ),
      ),
    );
  }
}
