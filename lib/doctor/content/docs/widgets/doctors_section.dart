import 'package:flutter/material.dart';
import 'package:wellwiz/utils/hospital_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'hospital_card.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/utils/hospital_rating_service.dart';
import 'package:wellwiz/utils/hospital_key.dart';

class NearbyHospitalsSection extends StatefulWidget {
  final List<Hospital> within20km;
  final List<Hospital> within5km;
  final List<Hospital> within1km;

  const NearbyHospitalsSection({
    Key? key,
    this.within20km = const [],
    this.within5km = const [],
    this.within1km = const [],
  }) : super(key: key);

  @override
  State<NearbyHospitalsSection> createState() => _NearbyHospitalsSectionState();
}

class _NearbyHospitalsSectionState extends State<NearbyHospitalsSection> {
  int selectedTier = 0; // 0: 1.5km, 1: 5km, 2: 20km

  Map<String, double> hospitalRatings = {};
  bool loadingRatings = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => loadingRatings = true);
    final allHospitals = [
      ...widget.within1km,
      ...widget.within5km,
      ...widget.within20km,
    ];
    Map<String, double> ratings = {};
    await Future.wait(allHospitals.map((hospital) async {
      final key = generateHospitalKey(hospital);
      final reviews = await HospitalRatingService.getRatingsForHospital(key);
      if (reviews.isNotEmpty) {
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        ratings[key] = avg;
      } else {
        ratings[key] = 0.0;
      }
    }));
    setState(() {
      hospitalRatings = ratings;
      loadingRatings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiers = [
      {'label': '<1.5km', 'hospitals': widget.within1km},
      {'label': '<5km', 'hospitals': widget.within5km},
      {'label': '<20km', 'hospitals': widget.within20km},
    ];
    final hospitals = tiers[selectedTier]['hospitals'] as List<Hospital>;
    final green = ColorPalette.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 0),
          child: Text(
            'Nearby Hospitals',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorPalette.black),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 0),
          child: Row(
            children: [
              Wrap(
                spacing: 6,
                children: List.generate(3, (i) => ChoiceChip(
                  label: Text(
                    tiers[i]['label'] as String,
                    style: TextStyle(
                      color: selectedTier == i ? Colors.white : ColorPalette.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: selectedTier == i,
                  selectedColor: green,
                  backgroundColor: Colors.grey[200],
                  onSelected: (selected) {
                    if (selected) setState(() => selectedTier = i);
                  },
                )),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: loadingRatings
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  itemBuilder: (context, index) => const HospitalCardShimmer(),
                )
              : hospitals.isEmpty
                  ? const Center(child: Text('No hospitals found.'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hospitals.length,
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      itemBuilder: (context, index) {
                        final hospital = hospitals[index];
                        final key = generateHospitalKey(hospital);
                        final avgRating = hospitalRatings[key];
                        return HospitalCard(hospital: hospital, averageRating: avgRating);
                      },
                    ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
} 