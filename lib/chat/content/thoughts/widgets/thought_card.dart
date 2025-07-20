import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wellwiz/utils/thought_service.dart';
import 'package:wellwiz/mental_peace/content/models/thought.dart';

class ThoughtCard extends StatefulWidget {
  const ThoughtCard({super.key});

  @override
  State<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends State<ThoughtCard> {
  int currentThoughtIndex = 0;
  late List<int> imageIndices;
  final CarouselSliderController _carouselController = CarouselSliderController();
  bool _isLoading = true;
  List<Thought> _cachedThoughts = [];
  List<Thought> _combinedThoughts = [];
  bool _hasCachedThoughts = false;

  // Keep existing hardcoded thoughts as fallback
  final List<String> fallbackThoughts = [
    "In the garden of health, every breath is a petal, every heartbeat a bloom.",
    "Hope is the gentle breeze that carries the fragrance of healing."
  ];

  @override
  void initState() {
    super.initState();
    final rand = Random();
    // Only use available image (0.png)
    imageIndices = List.generate(fallbackThoughts.length, (_) => 0);
    currentThoughtIndex = rand.nextInt(fallbackThoughts.length);
    
    // Create initial combined thoughts with fallbacks
    _createCombinedThoughts();
    
    // Initialize thoughts - always start with fallbacks
    _initializeThoughts();
    
    // Start auto-scroll
    Future.delayed(const Duration(seconds: 10), _autoScroll);
  }

  void _createCombinedThoughts() {
    // Create fallback thoughts as Thought objects
    final fallbackThoughtObjects = fallbackThoughts.asMap().entries.map((entry) {
      final index = entry.key;
      final quote = entry.value;
      return Thought(
        id: 'fallback_$index',
        quote: quote,
        speaker: 'Wisher',
        image: 'assets/thought/${imageIndices[index]}.png',
      );
    }).toList();
    
    // Combine fallbacks with cached thoughts
    _combinedThoughts = [...fallbackThoughtObjects, ..._cachedThoughts];
  }

  Future<void> _initializeThoughts() async {
    // Always start with fallback thoughts to prevent flicker
    setState(() {
      _isLoading = false;
    });
    
    // Get cached thoughts in background
    final cachedThoughts = ThoughtService.getCachedThoughts();
    
    if (cachedThoughts.isNotEmpty && mounted) {
      // Update cached thoughts and recreate combined list
      setState(() {
        _cachedThoughts = cachedThoughts;
        _hasCachedThoughts = true;
        _createCombinedThoughts();
        // Keep the same current index if it's still valid
        if (currentThoughtIndex >= _combinedThoughts.length) {
          currentThoughtIndex = Random().nextInt(_combinedThoughts.length);
        }
      });
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    _carouselController.nextPage(duration: Duration(milliseconds: 600));
    Future.delayed(const Duration(seconds: 10), _autoScroll);
  }

  Widget _buildThoughtImage(String imageUrl) {
    if (ThoughtService.isRemoteImage(imageUrl)) {
      return FutureBuilder<File?>(
        future: ThoughtService.getCachedImage(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
            );
          } else {
            return Image.asset(
              'assets/thought/0.png',
              fit: BoxFit.cover,
              width: double.infinity,
            );
          }
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 340,
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(42),
            bottomRight: Radius.circular(42),
          ),
          color: Colors.grey.shade800,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.green.shade300,
          ),
        ),
      );
    }

    // Use the combined thoughts list which always includes fallbacks
    final itemCount = _combinedThoughts.length;

    return CarouselSlider.builder(
        carouselController: _carouselController,
        itemCount: itemCount,
        options: CarouselOptions(
          height: 340,
          viewportFraction: 1.0, // Only center card visible
          enlargeCenterPage: false,
          padEnds: true,
          autoPlay: false, // We handle auto-scroll manually for more control
          enableInfiniteScroll: true,
          initialPage: currentThoughtIndex,
          onPageChanged: (index, reason) {
            setState(() {
              currentThoughtIndex = index;
            });
          },
          scrollPhysics: BouncingScrollPhysics(),
          pageSnapping: true,
          scrollDirection: Axis.horizontal,
        ),
        itemBuilder: (context, index, realIdx) {
          final thought = _combinedThoughts[index];
          final isFallback = thought.id.startsWith('fallback_');
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
              color: Colors.grey.shade800,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildThoughtImage(thought.image),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                    color: Colors.grey.shade800,
                  ),
                  padding:
                      EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        "\"${thought.quote}\"",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Mulish',
                            fontSize: 16),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          thought.speaker,
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
} 