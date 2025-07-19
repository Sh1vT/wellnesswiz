import 'package:geolocator/geolocator.dart';
import 'package:wellwiz/doctor/doctor_page.dart';
import 'package:wellwiz/utils/hospital_utils.dart';
import 'package:wellwiz/utils/hospital_key.dart';
import 'package:wellwiz/utils/hospital_rating_service.dart';
import 'package:wellwiz/utils/user_info_cache.dart';

Future<void> initializeAppStartup() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLng = position.longitude;
      final hospitals1km = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 6, maxResults: 20);
      final hospitals5kmRaw = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 5, maxResults: 20);
      final hospitals20kmRaw = await fetchNearbyHospitals(userLat: userLat, userLng: userLng, geohashPrecision: 4, maxResults: 20);
      // Deduplicate: only show hospitals in their closest tier
      final hospitals1kmSet = hospitals1km.map((h) => h.name + h.latitude.toString() + h.longitude.toString()).toSet();
      final hospitals5km = hospitals5kmRaw.where((h) => !hospitals1kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString())).toList();
      final hospitals5kmSet = hospitals5km.map((h) => h.name + h.latitude.toString() + h.longitude.toString()).toSet();
      final hospitals20km = hospitals20kmRaw.where((h) =>
        !hospitals1kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString()) &&
        !hospitals5kmSet.contains(h.name + h.latitude.toString() + h.longitude.toString())
      ).toList();
      DoctorPage.setupHospitals(
        within20km: hospitals20km,
        within5km: hospitals5km,
        within1km: hospitals1km,
      );
      // Fetch ratings for all hospitals (ignore errors)
      final allHospitals = [...hospitals1km, ...hospitals5km, ...hospitals20km];
      await Future.wait(allHospitals.map((hospital) async {
        try {
          final key = generateHospitalKey(hospital);
          final ratings = await HospitalRatingService.getRatingsForHospital(key);
          HospitalRatingService.cacheRatings(key, ratings);
        } catch (_) {}
      }));
    }
  } catch (e) {
    print('Error fetching user location or hospitals: $e');
  }
} 