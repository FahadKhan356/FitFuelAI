import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Calories Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ADE80), Color(0xFF34D399)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Calories', style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 8),
                  Text(
                    '1,420 kcal',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consumed', style: Theme.of(context).textTheme.bodySmall),
                          Text('580 kcal', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Burned', style: Theme.of(context).textTheme.bodySmall),
                          Text('245 kcal', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Macros Section
            Text('Macronutrients', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroCard(
                    label: 'Protein',
                    value: '65g',
                    goal: '140g',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MacroCard(
                    label: 'Carbs',
                    value: '120g',
                    goal: '250g',
                    color: Colors.yellow,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MacroCard(
                    label: 'Fats',
                    value: '42g',
                    goal: '70g',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Recent Meals
            Text('Recent Meals', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            _MealItem(
              name: 'Avocado Toast with Egg',
              time: '08:30 AM',
              calories: '340 kcal',
            ),
            SizedBox(height: 12),
            _MealItem(
              name: 'Grilled Salmon Salad',
              time: '01:45 PM',
              calories: '480 kcal',
            ),
            SizedBox(height: 24),
            // Scan Food Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.camera_alt),
                label: Text('Scan Food'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 4),
          Text('/ $goal', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final String name;
  final String time;
  final String calories;

  const _MealItem({
    required this.name,
    required this.time,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fastfood, color: Colors.grey),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 4),
                Text(time, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text(calories, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
