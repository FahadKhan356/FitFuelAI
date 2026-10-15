enum ExerciseType {
  squat,
  pushUp,
  lunge,
  plank,
  bicepCurl,
  shoulderPress,
  deadlift,
  pullUp,
  lateralRaise,
  sitUp,
}

class Exercise {
  final ExerciseType type;
  final String name;
  final String emoji;
  final String cameraPosition; // instruction for user
  final String targetMuscles;
  final bool hasReps; // false for plank (time-based)
  final int targetReps;
  final int targetSets;

  const Exercise({
    required this.type,
    required this.name,
    required this.emoji,
    required this.cameraPosition,
    required this.targetMuscles,
    this.hasReps = true,
    this.targetReps = 12,
    this.targetSets = 3,
  });
}

// All supported exercises
const List<Exercise> kExercises = [
  Exercise(
    type: ExerciseType.squat,
    name: 'Squat',
    emoji: '🏋️',
    cameraPosition: 'Place phone to your side — full body must be visible',
    targetMuscles: 'Quads • Glutes • Core',
    targetReps: 15,
  ),
  Exercise(
    type: ExerciseType.pushUp,
    name: 'Push-up',
    emoji: '💪',
    cameraPosition: 'Place phone at floor level to your side',
    targetMuscles: 'Chest • Shoulders • Triceps',
    targetReps: 12,
  ),
  Exercise(
    type: ExerciseType.lunge,
    name: 'Lunge',
    emoji: '🦵',
    cameraPosition: 'Place phone to your side — full body visible',
    targetMuscles: 'Quads • Glutes • Hamstrings',
    targetReps: 10,
  ),
  Exercise(
    type: ExerciseType.plank,
    name: 'Plank',
    emoji: '⚡',
    cameraPosition: 'Place phone at floor level to your side',
    targetMuscles: 'Core • Shoulders • Back',
    hasReps: false,
    targetReps: 0,
  ),
  Exercise(
    type: ExerciseType.bicepCurl,
    name: 'Bicep Curl',
    emoji: '🏋️',
    cameraPosition: 'Stand facing camera — full arm must be visible',
    targetMuscles: 'Biceps • Forearms',
    targetReps: 12,
  ),
  Exercise(
    type: ExerciseType.shoulderPress,
    name: 'Shoulder Press',
    emoji: '🙆',
    cameraPosition: 'Stand facing camera — full body visible',
    targetMuscles: 'Shoulders • Triceps • Traps',
    targetReps: 10,
  ),
  Exercise(
    type: ExerciseType.deadlift,
    name: 'Deadlift',
    emoji: '🔥',
    cameraPosition: 'Place phone to your side — very important for back check',
    targetMuscles: 'Back • Glutes • Hamstrings',
    targetReps: 8,
  ),
  Exercise(
    type: ExerciseType.pullUp,
    name: 'Pull-up',
    emoji: '🦾',
    cameraPosition: 'Phone facing you — full body from bar to feet',
    targetMuscles: 'Lats • Biceps • Rear Delts',
    targetReps: 8,
  ),
  Exercise(
    type: ExerciseType.lateralRaise,
    name: 'Lateral Raise',
    emoji: '🏅',
    cameraPosition: 'Stand facing camera — both arms visible',
    targetMuscles: 'Side Delts • Traps',
    targetReps: 15,
  ),
  Exercise(
    type: ExerciseType.sitUp,
    name: 'Sit-up',
    emoji: '🎯',
    cameraPosition: 'Place phone to your side at floor level',
    targetMuscles: 'Abs • Hip Flexors',
    targetReps: 20,
  ),
];
