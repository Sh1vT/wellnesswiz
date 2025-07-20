import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wellwiz/utils/hospital_utils.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/utils/hospital_key.dart';
import 'package:wellwiz/utils/hospital_rating_service.dart';
import '../models/hospital_rating.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalDetailsBottomSheet extends StatefulWidget {
  final Hospital hospital;
  const HospitalDetailsBottomSheet({super.key, required this.hospital});

  @override
  State<HospitalDetailsBottomSheet> createState() => _HospitalDetailsBottomSheetState();
}

class _HospitalDetailsBottomSheetState extends State<HospitalDetailsBottomSheet> {
  double userRating = 0;
  String reviewText = '';
  List<HospitalRating> ratings = [];
  bool loading = true;
  String? userId;
  String userName = '';
  late TextEditingController _reviewController;
  bool showReviewControls = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _init();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final key = generateHospitalKey(widget.hospital);
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
    userName = user?.displayName ?? '';
    final fetchedRatings = await HospitalRatingService.getRatingsForHospital(key);
    final userRatingObj = fetchedRatings.firstWhere(
      (r) => r.userId == userId,
      orElse: () => HospitalRating(userId: userId ?? '', userName: userName, rating: 0, review: '', timestamp: DateTime.now()),
    );
    setState(() {
      ratings = fetchedRatings;
      userRating = userRatingObj.rating;
      reviewText = userRatingObj.review;
      _reviewController.text = reviewText;
      loading = false;
      showReviewControls = false; // Hide controls after (re)load
    });
  }

  Future<void> _submitRating() async {
    if (userId == null) return;
    final key = generateHospitalKey(widget.hospital);
    final rating = HospitalRating(
      userId: userId!,
      userName: userName,
      rating: userRating,
      review: reviewText,
      timestamp: DateTime.now(),
    );
    await HospitalRatingService.submitRating(key, rating);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.hospital.raw['District']?.toString() ?? '';
    final address = widget.hospital.raw['Address']?.toString() ?? '';
    const assetImage = 'assets/hospitals/1.jpg';
    final avgRating = ratings.isEmpty ? 0.0 : (ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length).toDouble();
    final userHasReview = userRating > 0;
    final mapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${widget.hospital.latitude},${widget.hospital.longitude}';
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 28,
                width: 180,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
              ),
              Container(
                height: 18,
                width: 120,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
              ),
              Container(
                height: 16,
                width: 100,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
              ),
              Container(
                height: 18,
                width: 80,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
              ),
              Row(
                children: [
                  Container(
                    height: 32,
                    width: 90,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 32,
                    width: 120,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                assetImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.hospital.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorPalette.blackDarker),
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(city, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(address, style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ColorPalette.blackDarker),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: ColorPalette.green, size: 18),
                const SizedBox(width: 8),
                Text('(${ratings.length} reviews)', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(mapsUrl);
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.location_on, color: ColorPalette.green),
                    label: const Text('Locate', style: TextStyle(color: ColorPalette.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ColorPalette.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showReviewControls = true;
                        if (!userHasReview) {
                          userRating = 0;
                          reviewText = '';
                          _reviewController.text = '';
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.green,
                      foregroundColor: Colors.white,
                      // side: const BorderSide(color: ColorPalette.green),
                      elevation: 0,
                    ),
                    child: Text(userHasReview ? 'Edit Review' : 'Leave a Review', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (showReviewControls)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: ColorPalette.green,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            userRating = index + 1.0;
                          });
                        },
                        splashRadius: 20,
                      );
                    }),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Write a review...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    controller: _reviewController,
                    onChanged: (text) {
                      setState(() {
                        reviewText = text;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: userRating == 0 || loading ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.green,
                          ),
                          child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit', style: TextStyle(color: Colors.white),),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              showReviewControls = false;
                              // Restore previous review if editing
                              final userRatingObj = ratings.firstWhere(
                                (r) => r.userId == userId,
                                orElse: () => HospitalRating(userId: userId ?? '', userName: userName, rating: 0, review: '', timestamp: DateTime.now()),
                              );
                              userRating = userRatingObj.rating;
                              reviewText = userRatingObj.review;
                              _reviewController.text = reviewText;
                            });
                          },
                          child: const Text('Cancel', style: TextStyle(color: ColorPalette.black),),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorPalette.blackDarker)),
                const SizedBox(height: 8),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (ratings.isEmpty)
                  const Text('No reviews yet.')
                else
                  ...ratings.reversed.map((r) => _buildReviewTile(r)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRow(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: ColorPalette.green,
          size: size,
        );
      }),
    );
  }

  Widget _buildReviewTile(HospitalRating r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.userName.isNotEmpty ? r.userName : 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ColorPalette.blackDarker),
              ),
              const SizedBox(width: 8),
              _buildStarRow(r.rating),
              const SizedBox(width: 8),
              Text(
                r.timestamp.toLocal().toString().split(' ')[0],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (r.review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.review),
          ],
        ],
      ),
    );
  }
} 