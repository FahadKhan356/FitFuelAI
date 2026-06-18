import 'package:flutter/material.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({Key? key}) : super(key: key);

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  double waterIntake = 1750;
  double waterGoal = 3000;

  @override
  Widget build(BuildContext context) {
    var percentage = waterIntake / waterGoal;

    return Scaffold(
      appBar: AppBar(title: const Text('Water Intake')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Water tracker visualization
            Center(
              child: Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF34D399), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      height: 300 * (1 - percentage),
                      alignment: Alignment.bottomCenter,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${waterIntake.toInt()}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Text(
                            '/ ${waterGoal.toInt()} ml',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(waterIntake / waterGoal * 100).toStringAsFixed(0)}% Done',
                            style: const TextStyle(color: Color(0xFF34D399)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Quick add buttons
            Text('Quick Log', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickLogButton(
                  label: '250ml\nGlass',
                  icon: Icons.local_drink_outlined,
                  onPressed: () => setState(() => waterIntake += 250),
                ),
                _QuickLogButton(
                  label: '500ml\nBottle',
                  icon: Icons.local_drink_outlined,
                  onPressed: () => setState(() => waterIntake += 500),
                ),
                _QuickLogButton(
                  label: '750ml\nLarge',
                  icon: Icons.local_drink_outlined,
                  onPressed: () => setState(() => waterIntake += 750),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // History
            Text('Today\'s History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _HistoryItem(time: '08:30 AM', amount: '+250ml'),
            const SizedBox(height: 8),
            const _HistoryItem(time: '10:15 AM', amount: '+500ml'),
            const SizedBox(height: 8),
            const _HistoryItem(time: '01:00 PM', amount: '+1000ml'),
          ],
        ),
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {

  const _QuickLogButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF374151)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF34D399), size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
}

class _HistoryItem extends StatelessWidget {

  const _HistoryItem({required this.time, required this.amount});
  final String time;
  final String amount;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: Theme.of(context).textTheme.bodyMedium),
          Text(amount, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
}
