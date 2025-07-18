import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class ExerciseScreen extends StatefulWidget {
  final String exercise;

  ExerciseScreen({required this.exercise});

  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late Timer _timer;
  int _totalDuration = 0;
  int _elapsedTime = 0;
  int _instructionElapsedTime = 0;
  int _currentPhaseIndex = 0;
  String _currentInstruction = 'Get ready...';
  late AudioPlayer _audioPlayer;
  bool _isFadingOut = false;
  double _opacity = 1.0;

  @override
  void initState() {
    print("exercisepage");
    super.initState();
    _audioPlayer = AudioPlayer();
    _playMusic();
    _totalDuration = getTotalDurationForExercise(widget.exercise) ?? 120;
    if (_totalDuration < 120) {
      _totalDuration = 120;
    }
    startTimer();
  }

  int? getTotalDurationForExercise(String exercise) {
    return exerciseSteps[exercise]
        ?.fold<int>(0, (total, step) => total + (step['duration'] as int));
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTime < _totalDuration) {
          _elapsedTime++;
          _instructionElapsedTime++;
          if (_instructionElapsedTime ==
              (exerciseSteps[widget.exercise]![_currentPhaseIndex]['duration']
                  as int)) {
            _fadeOutInstruction();
          }
        } else {
          _showCompletionDialog();
          _timer.cancel();
        }
      });
    });
  }

  Future<void> _playMusic() async {
    try {
      int randomFileNumber = Random().nextInt(4) + 1;
      await _audioPlayer.setSource(AssetSource('music/$randomFileNumber.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  void _fadeOutInstruction() {
    setState(() {
      _opacity = 0.0;
      _isFadingOut = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      _updateInstruction();
      _fadeInInstruction();
    });
  }

  void _fadeInInstruction() {
    setState(() {
      _opacity = 1.0;
      _isFadingOut = false;
    });
  }

  void _updateInstruction() {
    if (exerciseSteps[widget.exercise] != null) {
      int totalSteps = exerciseSteps[widget.exercise]!.length;

      if (_currentPhaseIndex < totalSteps - 1) {
        _currentPhaseIndex++;
      } else {
        _currentPhaseIndex = 0;
      }

      _currentInstruction =
          exerciseSteps[widget.exercise]![_currentPhaseIndex]['instruction'];
      _instructionElapsedTime = 0;
    }
  }

  void _showCompletionDialog() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Exercise Completed!'),
          content: Text('Great job! You have completed the exercise.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.grey.shade800,
              size: 18,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Text(
          widget.exercise + " Breathing",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 1),
              child: Text(
                _currentInstruction,
                style: TextStyle(
                    fontSize: 30, color: Color.fromRGBO(106, 172, 67, 1), fontFamily: 'Mulish'),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            Container(
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: ClipOval(
                  child: Lottie.asset('assets/animations/breathing.json'),
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Time remaining: ',
                  style: TextStyle(
                    color: Color.fromRGBO(106, 172, 67, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                  ),
                ),
                Text(
                  '${_totalDuration - _elapsedTime} seconds',
                  style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Mulish'),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

final Map<String, List<Map<String, dynamic>>> exerciseSteps = {
  'Deep': [
    {'instruction': 'Inhale deeply', 'duration': 8},
    {'instruction': 'Hold your breath', 'duration': 8},
    {'instruction': 'Exhale slowly', 'duration': 8},
  ],
  'Box': [
    {'instruction': 'Inhale for 6 seconds', 'duration': 6},
    {'instruction': 'Hold for 6 seconds', 'duration': 6},
    {'instruction': 'Exhale for 6 seconds', 'duration': 6},
    {'instruction': 'Hold for 6 seconds', 'duration': 6},
  ],
  '4-7-8': [
    {'instruction': 'Inhale for 4 seconds', 'duration': 4},
    {'instruction': 'Hold for 7 seconds', 'duration': 7},
    {'instruction': 'Exhale for 8 seconds', 'duration': 8},
  ],
  'Alternate Nostril': [
    {
      'instruction': 'Close right nostril and inhale through left nostril',
      'duration': 6
    },
    {'instruction': 'Hold breath, close both nostrils', 'duration': 6},
  ],
}; 