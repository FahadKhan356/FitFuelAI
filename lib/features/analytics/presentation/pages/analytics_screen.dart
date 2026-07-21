import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Weekly', 'Monthly', 'Yearly']
                  .map((period) => ChoiceChip(
                        label: Text(period),
                        selected: selectedPeriod == period,
                        onSelected: (selected) {
                          setState(() => selectedPeriod = period);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Avg Calories',
                    value: '2,045',
                    change: '-12%',
                    positive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Avg Water',
                    value: '2.4L',
                    change: '+5%',
                    positive: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Calorie Activity', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: const Center(child: Text('Chart Placeholder')),
            ),
            const SizedBox(height: 24),
            Text('Macro Distribution',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: const Center(child: Text('Pie Chart Placeholder')),
            ),
            const SizedBox(height: 24),
            Text('Weight Progress',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: const Center(child: Text('Weight Chart Placeholder')),
            ),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });
  final String label;
  final String value;
  final String change;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              color: positive ? Color(0xFF10B981) : Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
}
