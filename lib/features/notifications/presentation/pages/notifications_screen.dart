import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _pulseController;

  final List<NotificationItem> notifications = [
    NotificationItem(
      icon: Icons.local_fire_department_rounded,
      iconColor: Color(AppColors.streakOrange),
      iconBg: Color(0xFFFFF0DE),
      title: 'Streak Reminder',
      description: 'You\'re on a 12-day streak! Keep it going',
      time: '2 hours ago',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.water_drop_rounded,
      iconColor: Color(AppColors.secondary),
      iconBg: Color(0xFFE0F2FE),
      title: 'Hydration Alert',
      description: 'Time to drink water! 1.5L remaining',
      time: '1 hour ago',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.emoji_events_rounded,
      iconColor: Color(AppColors.xpGold),
      iconBg: Color(0xFFFEF3C7),
      title: 'Achievement Unlocked',
      description: '7-Day streak badge earned! 🔥',
      time: '30 min ago',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.restaurant_rounded,
      iconColor: Color(AppColors.primary),
      iconBg: Color(0xFFDBEAFE),
      title: 'Meal Logged',
      description: 'Lunch: 650 calories • Protein: 35g',
      time: '3 hours ago',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.trending_down_rounded,
      iconColor: Color(AppColors.success),
      iconBg: Color(0xFFD1FAE5),
      title: 'Weight Milestone',
      description: 'You\'ve lost 4.2kg! Keep pushing!',
      time: '1 day ago',
      isUnread: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(),

            const SizedBox(height: 24),

            // ── Notification List ──
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _fadeController,
                      curve: Curves.easeInOut,
                    ),
                    child: child,
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(AppColors.surface),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(AppColors.textPrimary),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title with badge - wrapped in Expanded for proper sizing
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(AppColors.textPrimary),
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Unread badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(AppColors.authPurple),
                        Color(AppColors.authPurpleDark),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(AppColors.authPurple).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '2 new',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Mark all as read button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Mark all as read logic
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(AppColors.authPurpleBg),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(AppColors.authPurple).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.authPurple),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(int index) {
    final notification = notifications[index];
    final delay = index * 0.08;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeController]),
      builder: (context, child) {
        final slideAnimation = CurvedAnimation(
          parent: _slideController,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeOutCubic),
        ).value;

        final fadeAnimation = CurvedAnimation(
          parent: _fadeController,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeIn),
        ).value;

        final scaleAnimation = 1.0 - (0.1 * (1 - slideAnimation));

        return Transform.scale(
          scale: scaleAnimation,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - slideAnimation)),
            child: Opacity(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(AppColors.surface),
              Color(AppColors.surfaceLight),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Navigate to notification detail
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Color(AppColors.authPurple).withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: notification.isUnread
                      ? Color(AppColors.authPurple).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with pulse animation
                  AnimatedBuilder(
                    animation: notification.isUnread
                        ? _pulseController
                        : AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      if (!notification.isUnread) return child!;

                      final scale = 1.0 + (_pulseController.value * 0.05);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: notification.iconBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: notification.iconColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.iconColor,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: Color(AppColors.textPrimary),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (notification.isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(AppColors.authPurple),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(AppColors.authPurple).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(AppColors.textSecondary),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Color(AppColors.textTertiary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(AppColors.textTertiary),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String time;
  final bool isUnread;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.time,
    required this.isUnread,
  });
}