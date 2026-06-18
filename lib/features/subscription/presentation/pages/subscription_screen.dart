import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              alignment: Alignment.center,
              child: const Icon(Icons.star, size: 80, color: Color(0xFFFCD34D)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Master Your Nutrition',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Unlock all features and reach your goals faster',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Features
            Text('Premium Features', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _FeatureItem(
              icon: Icons.no_food,
              title: 'Unlimited Scanning',
              description: 'No daily limits',
            ),
            const _FeatureItem(
              icon: Icons.bar_chart,
              title: 'Advanced Analytics',
              description: 'Detailed insights',
            ),
            const _FeatureItem(
              icon: Icons.psychology,
              title: 'AI Meal Planning',
              description: 'Personalized plans',
            ),
            const _FeatureItem(
              icon: Icons.emoji_events,
              title: 'Premium Badges',
              description: 'Exclusive rewards',
            ),
            const SizedBox(height: 32),
            // Pricing
            Text('Choose Your Plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _PricingCard(
              title: 'Monthly',
              price: r'$9.99',
              period: '/month',
              selected: false,
            ),
            const SizedBox(height: 12),
            const _PricingCard(
              title: 'Annual',
              price: r'$4.99',
              period: '/month',
              subtitle: 'Save 50%',
              selected: true,
            ),
            const SizedBox(height: 12),
            const _PricingCard(
              title: 'Lifetime',
              price: r'$99.99',
              period: 'One Time',
              selected: false,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Start 7-Day Free Trial'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Cancel anytime. No credit card required.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
}

class _FeatureItem extends StatelessWidget {

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4ADE80), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
}

class _PricingCard extends StatelessWidget {

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.subtitle,
    required this.selected,
  });
  final String title;
  final String price;
  final String period;
  final String? subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Color(0xFF4ADE80) : Color(0xFF374151),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ADE80),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: Theme.of(context).textTheme.displaySmall),
              SizedBox(width: 4),
              Text(period, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
}
