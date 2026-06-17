import 'package:flutter/material.dart';

class WeightTrackerScreen extends StatelessWidget {
  const WeightTrackerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weight Tracking')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current weight
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Weight', style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 8),
                  Text(
                    '72.4 kg',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '↓ -0.4kg since yesterday',
                    style: TextStyle(color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Chart placeholder
            Text('Weight Trend', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chart will be rendered here'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Goal Progress
            Text('Goal Progress', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
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
                          Text('Start', style: Theme.of(context).textTheme.bodySmall),
                          Text('77kg', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('51% Complete', style: TextStyle(color: Color(0xFF4ADE80))),
                          Text('4.6kg to go', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Goal', style: Theme.of(context).textTheme.bodySmall),
                          Text('68kg', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.51,
                      minHeight: 8,
                      backgroundColor: Color(0xFF374151),
                      valueColor: AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // BMI Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF374151)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current BMI', style: Theme.of(context).textTheme.bodySmall),
                      Text('23.4', style: Theme.of(context).textTheme.titleLarge),
                      Text('Normal', style: TextStyle(color: Color(0xFF10B981))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Ideal Range', style: Theme.of(context).textTheme.bodySmall),
                      Text('18.5 - 24.9', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
