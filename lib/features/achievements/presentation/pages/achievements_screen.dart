import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Achievements')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level and XP
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF374151)),
                gradient: LinearGradient(
                  colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level', style: Theme.of(context).textTheme.bodySmall),
                          Text('14', style: Theme.of(context).textTheme.displayLarge),
                          Text('Elite Rank', style: TextStyle(color: Color(0xFFFCD34D))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('XP Progress', style: Theme.of(context).textTheme.bodySmall),
                          Text('12,450 / 15,000',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('83% to Level 15',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.83,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Streak
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: Color(0xFFFF8A50), size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day Streak', style: Theme.of(context).textTheme.titleMedium),
                        Text('12 days', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Text('Keep it up!',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Badges
            Text('Badges Gallery', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _BadgeCard(
                  icon: Icons.bolt,
                  label: 'Early Bird',
                  color: Color(0xFFFCD34D),
                  unlocked: true,
                ),
                _BadgeCard(
                  icon: Icons.water_drop,
                  label: 'H2O Master',
                  color: Color(0xFF60A5FA),
                  unlocked: true,
                ),
                _BadgeCard(
                  icon: Icons.track_changes,
                  label: 'Macro King',
                  color: Color(0xFFA78BFA),
                  unlocked: true,
                ),
                _BadgeCard(
                  icon: Icons.shield,
                  label: 'Consistent',
                  color: Color(0xFF4ADE80),
                  unlocked: false,
                ),
                _BadgeCard(
                  icon: Icons.fastfood,
                  label: 'First Scan',
                  color: Color(0xFF10B981),
                  unlocked: false,
                ),
                _BadgeCard(
                  icon: Icons.star,
                  label: 'AI Expert',
                  color: Color(0xFFF87171),
                  unlocked: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool unlocked;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? Color(0xFF1F2937) : Color(0xFF1F2937).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? color : Color(0xFF374151),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: unlocked ? color : Colors.grey, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
