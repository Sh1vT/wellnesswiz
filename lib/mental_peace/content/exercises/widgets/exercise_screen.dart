import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ExerciseScreenState extends State<ExerciseScreen> with WidgetsBindingObserver {
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
  bool _wasPausedByLifecycle = false;

  @override
  void initState() {
    //print("exercisepage");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        //print(
          // 'Playing random music track: ${randomIndex + 1}/${cachedMusics.length}: ${cachedMusics[randomIndex].id}',
        // );
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
      //print('Audio started playing');
    } catch (e) {
      //print('Error loading audio: $e');
      // Final fallback
      try {
        await _audioPlayer.setSource(AssetSource('music/1.mp3'));
        await _audioPlayer.resume();
        //print('Fallback audio started playing');
      } catch (e) {
        //print('Error loading fallback audio: $e');
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
              style: TextButton.styleFrom(
                backgroundColor: ColorPalette.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      if (_timer.isActive) {
        _timer.cancel();
      }
      await _audioPlayer.pause();
    } else {
      startTimer();
      await _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is going to background
        print('App going to background, current pause state: $_isPaused');
        if (!_isPaused) {
          _wasPausedByLifecycle = true;
          _pauseExercise();
          print('Exercise paused by lifecycle');
        }
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground - stay paused, let user decide
        print('App resumed, exercise pause state: $_isPaused');
        // No auto-resume, user can manually press play button
        break;
      default:
        break;
    }
  }

  void _pauseExercise() {
    print('Pausing exercise - timer active: ${_timer.isActive}');
    setState(() {
      _isPaused = true;
    });
    if (_timer.isActive) {
      _timer.cancel();
      print('Timer cancelled');
    }
    _audioPlayer.pause();
    print('Audio paused');
  }

  void _resumeExercise() {
    print('Resuming exercise');
    setState(() {
      _isPaused = false;
    });
    startTimer();
    _audioPlayer.resume();
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
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
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
                          SizedBox(width: 4),
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
                              color: _isPaused ? ColorPalette.green : Colors.amber,
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
    {'instruction': 'Inhale deeply', 'duration': 6},
    {'instruction': 'Now hold', 'duration': 6},
    {'instruction': 'Exhale slowly', 'duration': 6},
    {'instruction': 'Hold again', 'duration': 6},
  ],
  '4-7-8': [
    {'instruction': 'Inhale now', 'duration': 4},
    {'instruction': 'Hold for long', 'duration': 7},
    {'instruction': 'Exhale for longer', 'duration': 8},
  ],
  'Alternate Nostril': [
    {
      'instruction': 'Close right nostril, inhale from left',
      'duration': 6,
    },
    {'instruction': 'Close both and hold', 'duration': 6},
    {
      'instruction': 'Keep left closed, exhale from right',
      'duration': 6,
    },
    {'instruction': 'Close both, hold again', 'duration': 6},
  ],
  'Happy': [
    {'instruction': 'Smile and inhale deeply', 'duration': 5},
    {'instruction': 'Hold with a gentle smile', 'duration': 5},
    {'instruction': 'Exhale with joy', 'duration': 5},
    {'instruction': 'Pause and feel happy', 'duration': 5},
  ],
  'Calm Down': [
    {'instruction': 'Take a slow, calming breath in', 'duration': 6},
    {'instruction': 'Hold and center yourself', 'duration': 4},
    {'instruction': 'Release tension as you exhale', 'duration': 8},
    {'instruction': 'Rest in calmness', 'duration': 4},
  ],
  'Stress Relief': [
    {'instruction': 'Breathe in relaxation', 'duration': 7},
    {'instruction': 'Hold and let go of stress', 'duration': 5},
    {'instruction': 'Breathe out tension', 'duration': 7},
    {'instruction': 'Feel the relief', 'duration': 5},
  ],
  'Relaxed Mind': [
    {'instruction': 'Inhale peace and clarity', 'duration': 6},
    {'instruction': 'Hold and clear your mind', 'duration': 6},
    {'instruction': 'Exhale all thoughts', 'duration': 6},
    {'instruction': 'Rest in stillness', 'duration': 6},
  ],
};
