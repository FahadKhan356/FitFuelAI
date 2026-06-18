import 'package:flutter/material.dart';
import '../../../analytics/presentation/pages/analytics_screen.dart';
import '../../../food_scanner/presentation/pages/food_scanner_screen.dart';
import '../../../ai_coach/presentation/pages/ai_coach_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardContent(),
    AnalyticsScreen(),
    FoodScannerScreen(),
    AiCoachScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Analytics',
    'Food Scanner',
    'AI Coach',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
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

// MARK: - Dashboard Content

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Calories Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ADE80), Color(0xFF34D399)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Calories', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '1,420 kcal',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            // Macros Section
            Text('Macronutrients', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroCard(
                    label: 'Carbs',
                    value: '120g',
                    goal: '250g',
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 24),
            // Recent Meals
            Text('Recent Meals', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _MealItem(
              name: 'Avocado Toast with Egg',
              time: '08:30 AM',
              calories: '340 kcal',
            ),
            const SizedBox(height: 12),
            _MealItem(
              name: 'Grilled Salmon Salad',
              time: '01:45 PM',
              calories: '480 kcal',
            ),
            const SizedBox(height: 24),
            // Scan Food Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Food'),
              ),
            ),
          ],
        ),
      );
}

// MARK: - Private Widgets

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });
  final String label;
  final String value;
  final String goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF374151)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('/ $goal', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.name,
    required this.time,
    required this.calories,
  });
  final String name;
  final String time;
  final String calories;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF374151)),
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
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(time, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            Text(calories, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}