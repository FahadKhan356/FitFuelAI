import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF4ADE80).withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.person, size: 60, color: Color(0xFF4ADE80)),
            ),
            SizedBox(height: 16),
            Text('Alex Johnson', style: Theme.of(context).textTheme.displaySmall),
            Text('Premium Member', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 24),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  label: 'Streak',
                  value: '12 Days',
                ),
                _StatColumn(
                  label: 'Weight Lost',
                  value: '4.2 kg',
                ),
                _StatColumn(
                  label: 'Level',
                  value: '14',
                ),
              ],
            ),
            SizedBox(height: 32),
            // Account Settings
            Text('Account Settings', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.card_membership,
              title: 'Premium Subscription',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.favorite_outline,
              title: 'Health Goals',
              onTap: () {},
            ),
            SizedBox(height: 24),
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFEF4444)),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

class _StatColumn extends StatelessWidget {

  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
}

class _SettingsTile extends StatelessWidget {

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF374151)),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
}
