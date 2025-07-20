import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart'; // For unique ID generation
// For TimeOfDay
import 'dart:math';

class ThoughtsService {
  static final List<String> _thoughts = [
    // Deep, philosophical, health-related thoughts from real people
    "Take care of your body. It's the only place you have to live. – Jim Rohn",
    "Health is a state of complete harmony of the body, mind, and spirit. – B.K.S. Iyengar",
    "The greatest wealth is health. – Virgil",
    "It is health that is real wealth and not pieces of gold and silver. – Mahatma Gandhi",
    "To keep the body in good health is a duty… otherwise we shall not be able to keep our mind strong and clear. – Buddha",
    "A healthy outside starts from the inside. – Robert Urich",
    "Happiness is the highest form of health. – Dalai Lama",
    "The mind and body are not separate. What affects one, affects the other.",
    "Self-care is not a luxury, it is a necessity.",
    "Every human being is the author of their own health or disease. – Buddha",
    "He who has health has hope; and he who has hope has everything. – Arabian Proverb",
    "Your body hears everything your mind says.",
    "Rest and self-care are so important. When you take time to replenish your spirit, it allows you to serve others from the overflow. – Oprah Winfrey",
    "The groundwork for all happiness is good health. – Leigh Hunt",
    "Wellness is the natural state of my body. My body communicates with me, and I am willing to listen. – Louise Hay",
    "Caring for myself is not self-indulgence, it is self-preservation. – Audre Lorde",
    "You can’t pour from an empty cup. Take care of yourself first.",
    "A calm mind brings inner strength and self-confidence, so that’s very important for good health. – Dalai Lama",
    "Nourish to flourish.",
    "Let food be thy medicine and medicine be thy food. – Hippocrates",
    "Movement is a medicine for creating change in a person’s physical, emotional, and mental states. – Carol Welch",
    "The best doctor gives the least medicine. – Benjamin Franklin",
    "The part can never be well unless the whole is well. – Plato",
    "Health is not valued till sickness comes. – Thomas Fuller",
    "Take care of your body, it’s the only place you have to live. – Jim Rohn",
    "Your health is an investment, not an expense.",
    "Healing is a matter of time, but it is sometimes also a matter of opportunity. – Hippocrates",
    "The human body is the best picture of the human soul. – Ludwig Wittgenstein",
    "A fit body, a calm mind, a house full of love. These things cannot be bought – they must be earned.",
    "To enjoy the glow of good health, you must exercise. – Gene Tunney",
  ];

  static String getRandomThought() {
    final random = Random();
    return _thoughts[random.nextInt(_thoughts.length)];
  }

  String _generateUniqueId() {
    return DateFormat('yyyyMMddHHmmss').format(DateTime.now());
  }

  Future<void> scheduleDailyThoughtNotification(int hour, int minute) async {
    DateTime now = DateTime.now();
    DateTime nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
    if (nextOccurrence.isBefore(now)) {
      nextOccurrence = nextOccurrence.add(Duration(days: 1));
    }
    Duration initialDelay = nextOccurrence.difference(now);
    print('[DEBUG] Scheduling thoughtTask with inputData: {title: Positive Thought, description: ${getRandomThought()}, hour: $hour, minute: $minute}');
    await Workmanager().registerOneOffTask(
      'daily_thought_task_${nextOccurrence.millisecondsSinceEpoch}',
      'thoughtTask',
      initialDelay: initialDelay,
      inputData: {
        'title': "Positive Thought",
        'description': getRandomThought(),
        'hour': hour.toString(),
        'minute': minute.toString(),
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Call this from the WorkManager callback after showing the notification to reschedule for the next day
  static Future<void> rescheduleDailyThought(int hour, int minute) async {
    DateTime now = DateTime.now();
    DateTime nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: 1));
    Duration initialDelay = nextOccurrence.difference(now);
    await Workmanager().registerOneOffTask(
      'daily_thought_task_${nextOccurrence.millisecondsSinceEpoch}',
      'thoughtTask',
      initialDelay: initialDelay,
      inputData: {
        'title': "Positive Thought",
        'description': getRandomThought(),
        'hour': hour.toString(),
        'minute': minute.toString(),
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }


  Future<void> scheduleTestThoughtNotification() async {
    // Register a one-off task for testing purposes
    await Workmanager().registerOneOffTask(
      "test_thought_task", // A one-time task for testing
      "thoughtTask", // Differentiate from reminder tasks
      initialDelay: const Duration(seconds: 3),
    );
  }
}
