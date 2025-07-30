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
  // Remove showReviewControls variable

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
    });
  }

  Future<void> _showReviewDialog() async {
    double tempRating = userRating;
    String tempReview = reviewText;
    final tempController = TextEditingController(text: reviewText);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave a Review', style: TextStyle(fontFamily: 'Mulish', color: ColorPalette.blackDarker)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < tempRating ? Icons.star : Icons.star_border,
                    color: ColorPalette.green,
                    size: 32,
                  ),
                  onPressed: () {
                    tempRating = index + 1.0;
                    (context as Element).markNeedsBuild();
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tempController,
              style: const TextStyle(fontFamily: 'Mulish'),
              decoration: const InputDecoration(
                labelText: 'Write a review...',
                labelStyle: TextStyle(fontFamily: 'Mulish'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Mulish', color: ColorPalette.blackDarker)),
          ),
          ElevatedButton(
            onPressed: () async {
              userRating = tempRating;
              reviewText = tempController.text;
              Navigator.of(context).pop();
              await _submitRating();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.green,
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white, fontFamily: 'Mulish')),
          ),
        ],
      ),
    );
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
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
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
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.hospital.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorPalette.blackDarker, fontFamily: 'Mulish'),
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(city, style: const TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Mulish')),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(address, style: const TextStyle(fontSize: 15, fontFamily: 'Mulish')),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ColorPalette.blackDarker, fontFamily: 'Mulish'),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: ColorPalette.green, size: 18),
                const SizedBox(width: 8),
                Text('(${ratings.length} reviews)', style: const TextStyle(color: Colors.grey, fontFamily: 'Mulish')),
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
                    label: const Text('Locate', style: TextStyle(color: ColorPalette.green, fontFamily: 'Mulish')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ColorPalette.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showReviewDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.green,
                      foregroundColor: Colors.white,
                      // side: const BorderSide(color: ColorPalette.green),
                      elevation: 0,
                    ),
                    child: Text(userHasReview ? 'Edit Review' : 'Leave a Review', style: const TextStyle(color: Colors.white, fontFamily: 'Mulish')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorPalette.blackDarker, fontFamily: 'Mulish')),
                const SizedBox(height: 8),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (ratings.isEmpty)
                  const Text('No reviews yet.', style: TextStyle(fontFamily: 'Mulish'))
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ColorPalette.blackDarker, fontFamily: 'Mulish'),
              ),
              const SizedBox(width: 8),
              _buildStarRow(r.rating),
              const SizedBox(width: 8),
              Text(
                r.timestamp.toLocal().toString().split(' ')[0],
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Mulish'),
              ),
            ],
          ),
          if (r.review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.review, style: const TextStyle(fontFamily: 'Mulish')),
          ],
        ],
      ),
    );
  }
}