import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
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
            SizedBox(height: 24),
            // Stats overview
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
                SizedBox(width: 12),
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
            SizedBox(height: 24),
            // Charts
            Text('Calorie Activity', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Center(
                child: Text('Chart Placeholder'),
              ),
            ),
            SizedBox(height: 24),
            Text('Macro Distribution', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Center(
                child: Text('Pie Chart Placeholder'),
              ),
            ),
            SizedBox(height: 24),
            Text('Weight Progress', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Center(
                child: Text('Weight Chart Placeholder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool positive;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
