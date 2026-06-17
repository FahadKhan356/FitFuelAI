import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _NotificationTile(
            icon: Icons.notifications,
            title: 'Daily Reminder',
            description: 'Log your meals to stay on track',
            time: '2 hours ago',
          ),
          _NotificationTile(
            icon: Icons.local_drink_outlined,
            title: 'Water Reminder',
            description: 'Time to drink water!',
            time: '1 hour ago',
          ),
          _NotificationTile(
            icon: Icons.favorite,
            title: 'Achievement Unlocked',
            description: 'You reached your 7-day streak!',
            time: '30 min ago',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String time;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF4ADE80), size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: 4),
                Text(time, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
