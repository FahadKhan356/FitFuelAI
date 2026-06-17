import 'package:flutter/material.dart';

class MealTrackingScreen extends StatelessWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meal History')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Date filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search meals...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Meals by date
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),
          Text('Total: 1,450 / 2,100 kcal',
              style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 16),
          _MealCard(
            category: 'Breakfast',
            time: '08:30 AM',
            meal: 'Avocado Toast with Egg',
            calories: 340,
          ),
          SizedBox(height: 12),
          _MealCard(
            category: 'Lunch',
            time: '01:45 PM',
            meal: 'Grilled Salmon Salad',
            calories: 480,
          ),
          SizedBox(height: 12),
          _MealCard(
            category: 'Snack',
            time: '04:00 PM',
            meal: 'Greek Yogurt Bowl',
            calories: 210,
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String category;
  final String time;
  final String meal;
  final int calories;

  const _MealCard({
    required this.category,
    required this.time,
    required this.meal,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SizedBox(width: 8),
              Text(
                time,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(meal, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 8),
          Text(
            '$calories kcal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
