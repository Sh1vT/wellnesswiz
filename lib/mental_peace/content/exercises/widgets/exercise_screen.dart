import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wellwiz/utils/exercise_music_service.dart';
import 'package:wellwiz/utils/poppy_tile.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:marquee/marquee.dart';

class ExerciseScreen extends StatefulWidget {
  final String exercise;

  const ExerciseScreen({super.key, required this.exercise});

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
  bool _isTimerFading = false;
  double _timerOpacity = 1.0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  List<Map<String, dynamic>> _exerciseSteps = [];
  bool _isPaused = false;

  @override
  void initState() {
    print("exercisepage");
    super.initState();
    _audioPlayer = AudioPlayer();
    _playMusic();
    _initializeExerciseSteps();
    _totalDuration = getTotalDurationForExercise(widget.exercise) ?? 120;
    if (_totalDuration < 120) {
      _totalDuration = 120;
    }
    startTimer();
  }

  void _initializeExerciseSteps() {
    if (exerciseSteps[widget.exercise] != null) {
      _exerciseSteps = List.from(exerciseSteps[widget.exercise]!);
      _currentInstruction = _exerciseSteps[0]['instruction'];
    }
  }

  int? getTotalDurationForExercise(String exercise) {
    return exerciseSteps[exercise]?.fold<int>(
      0,
      (total, step) => total + (step['duration'] as int),
    );
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() {
        if (_elapsedTime < _totalDuration) {
          _elapsedTime++;
          _instructionElapsedTime++;
          if (_instructionElapsedTime ==
              (_exerciseSteps[_currentPhaseIndex]['duration'] as int)) {
            // Fade out timer before advancing
            _fadeOutTimerAndAdvance();
          }
        } else {
          _showCompletionDialog();
          _timer.cancel();
        }
      });
    });
  }

  void _fadeOutTimerAndAdvance() async {
    setState(() {
      _isTimerFading = true;
      _timerOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    _advanceToNextPhase();
    setState(() {
      _timerOpacity = 1.0;
      _isTimerFading = false;
    });
  }

  void _advanceToNextPhase() {
    if (_exerciseSteps.isNotEmpty) {
      int totalSteps = _exerciseSteps.length;

      if (_currentPhaseIndex < totalSteps - 1) {
        _currentPhaseIndex++;
      } else {
        _currentPhaseIndex = 0;
      }

      _currentInstruction = _exerciseSteps[_currentPhaseIndex]['instruction'];
      _instructionElapsedTime = 0;

      // Auto-scroll carousel to next instruction
      _carouselController.nextPage(duration: Duration(milliseconds: 600));
    }
  }

  Future<void> _playMusic() async {
    try {
      // Use cached music directly (no fetching needed)
      final cachedMusics = ExerciseMusicService.getCachedMusics();
      String musicUrl = 'assets/music/1.mp3'; // Default fallback

      if (cachedMusics.isNotEmpty) {
        // Pick a random track from available music
        final random = Random();
        final randomIndex = random.nextInt(cachedMusics.length);
        musicUrl = cachedMusics[randomIndex].url;
        print(
          'Playing random music track: ${randomIndex + 1}/${cachedMusics.length}: ${cachedMusics[randomIndex].id}',
        );
      }

      if (ExerciseMusicService.isRemoteMusic(musicUrl)) {
        // Handle remote music with caching
        final cachedFile = await ExerciseMusicService.getCachedMusic(musicUrl);
        if (cachedFile != null) {
          await _audioPlayer.setSource(DeviceFileSource(cachedFile.path));
        } else {
          // Fallback to default if remote music fails
          await _audioPlayer.setSource(AssetSource('music/1.mp3'));
        }
      } else {
        // Handle local asset
        await _audioPlayer.setSource(
          AssetSource(musicUrl.replaceFirst('assets/', '')),
        );
      }

      // Start playing the audio
      await _audioPlayer.resume();
      print('Audio started playing');
    } catch (e) {
      print('Error loading audio: $e');
      // Final fallback
      try {
        await _audioPlayer.setSource(AssetSource('music/1.mp3'));
        await _audioPlayer.resume();
        print('Fallback audio started playing');
      } catch (e) {
        print('Error loading fallback audio: $e');
      }
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

  void _togglePause() async {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _timer.cancel();
      await _audioPlayer.pause();
    } else {
      startTimer();
      await _audioPlayer.resume();
    }
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
      body: Container(
        width: screenWidth,
        height: screenHeight,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add responsive top spacing
            SizedBox(height: MediaQuery.paddingOf(context).top + 8),
            // Back button at the top
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: ColorPalette.black,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 40),
            // Vertical carousel for instructions
            SizedBox(
              height: 140, // Further reduced height to bring instructions closer
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timer (fixed left, vertically centered)
                  AnimatedOpacity(
                    opacity: _timerOpacity,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 60,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(106, 172, 67, 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.fromRGBO(106, 172, 67, 1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Color.fromRGBO(106, 172, 67, 1),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${(_exerciseSteps.isNotEmpty && _currentPhaseIndex < _exerciseSteps.length) ? ((_exerciseSteps[_currentPhaseIndex]['duration'] as int) - _instructionElapsedTime) : ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(106, 172, 67, 1),
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  // Carousel (instructions only)
                  Expanded(
                    child: CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: _exerciseSteps.length,
                      options: CarouselOptions(
                        height: 140, // Match container height
                        viewportFraction: 0.4,
                        enlargeCenterPage: true,
                        padEnds: true,
                        autoPlay: false,
                        enableInfiniteScroll: true,
                        initialPage: 0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentPhaseIndex = index;
                            _currentInstruction = _exerciseSteps[index]['instruction'];
                            _instructionElapsedTime = 0;
                          });
                        },
                        scrollPhysics: NeverScrollableScrollPhysics(),
                        pageSnapping: true,
                        scrollDirection: Axis.vertical,
                      ),
                      itemBuilder: (context, index, realIdx) {
                        final isCurrent = index == _currentPhaseIndex;
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                          alignment: Alignment.center,
                          child: Text(
                            _exerciseSteps[index]['instruction'],
                            style: TextStyle(
                              fontSize: isCurrent ? 18 : 15,
                              color: isCurrent
                                  ? Color.fromRGBO(106, 172, 67, 1)
                                  : Colors.grey.shade500,
                              fontFamily: 'Mulish',
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60), // Increased gap to move GIF further down
            // Breathing animation with PoppyTile background
            Container(
              margin: EdgeInsets.only(bottom: 30), // Add margin to prevent clipping
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none, // Prevent clipping of positioned children
                children: [
                  PoppyTile(
                    customBorderRadius: BorderRadius.circular(1000),
                    borderRadius: 100,
                    backgroundColor: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.6,
                      child: Lottie.asset('assets/animations/breathing.json'),
                    ),
                  ),
                  Positioned(
                    bottom: -15, // Positioned so circumference line goes through timer
                    child: GestureDetector(
                      onTap: _togglePause,
                      child: PoppyTile(
                        borderRadius: 25,
                        backgroundColor: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
                              color: _isPaused ? Colors.green : Colors.amber,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${(_totalDuration - _elapsedTime) ~/ 60}:${((_totalDuration - _elapsedTime) % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: ColorPalette.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Exercise title below the GIF
            SizedBox(height: 40),
            Text(
              "${widget.exercise} Breathing",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Mulish',
                color: ColorPalette.black,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(flex: 2), // Reduced flex to bring GIF more to center
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
      'duration': 6,
    },
    {'instruction': 'Hold breath, close both nostrils', 'duration': 6},
  ],
};
