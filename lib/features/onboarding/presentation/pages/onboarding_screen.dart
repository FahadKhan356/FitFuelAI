import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${currentStep + 1} of 8'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            Text(
              'Tell us about you',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Customize your nutrition goals',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / 8,
                minHeight: 4,
              ),
            ),
            SizedBox(height: 40),
            // Dynamic content based on step
            _buildStepContent(),
            SizedBox(height: 40),
            Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => currentStep--),
                      child: Text('Back'),
                    ),
                  ),
                if (currentStep > 0) SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep < 7) {
                        setState(() => currentStep++);
                      } else {
                        // Complete onboarding
                      }
                    },
                    child: Text(currentStep == 7 ? 'Complete' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return TextField(
          decoration: InputDecoration(hintText: 'Your Name'),
        );
      case 1:
        return TextField(
          decoration: InputDecoration(hintText: 'Age'),
          keyboardType: TextInputType.number,
        );
      case 2:
        return DropdownButtonFormField<String>(
          items: ['Male', 'Female', 'Other']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: InputDecoration(hintText: 'Gender'),
        );
      case 3:
        return TextField(
          decoration: InputDecoration(hintText: 'Height (cm)'),
          keyboardType: TextInputType.number,
        );
      case 4:
        return TextField(
          decoration: InputDecoration(hintText: 'Weight (kg)'),
          keyboardType: TextInputType.number,
        );
      case 5:
        return TextField(
          decoration: InputDecoration(hintText: 'Target Weight (kg)'),
          keyboardType: TextInputType.number,
        );
      case 6:
        return DropdownButtonFormField<String>(
          items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: InputDecoration(hintText: 'Activity Level'),
        );
      case 7:
        return DropdownButtonFormField<String>(
          items: ['Weight Loss', 'Weight Gain', 'Muscle Gain', 'Maintenance']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: InputDecoration(hintText: 'Goal Type'),
        );
      default:
        return SizedBox();
    }
  }
}
