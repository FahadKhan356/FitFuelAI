import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../widgets/exercise_card.dart';
import 'live_posture_screen.dart';

class PostureCoachScreen extends StatelessWidget {
  const PostureCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF181826) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF14142B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Posture Coach',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF14142B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Feature Header Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B4EE8), Color(0xFF7B6FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4EE8).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'REAL-TIME VISION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '🤖 AI Form Detector',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Live on-device joint tracking, real-time audio corrections, and spine/knee injury prevention.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '🏋️',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'SELECT EXERCISE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8A8A9A),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${kExercises.length} Movements',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B4EE8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // Exercise Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.98,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ex = kExercises[index];
                    return ExerciseCard(
                      exercise: ex,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LivePostureScreen(exercise: ex),
                          ),
                        );
                      },
                    );
                  },
                  childCount: kExercises.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 28),
            ),
          ],
        ),
      ),
    );
  }
}
