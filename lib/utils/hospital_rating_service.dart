import 'package:cloud_firestore/cloud_firestore.dart';
import '../doctor/content/docs/models/hospital_rating.dart';

class HospitalRatingService {
  static final _firestore = FirebaseFirestore.instance;
  static final Map<String, List<HospitalRating>> _ratingsCache = {};

  static CollectionReference<Map<String, dynamic>> _hospitalRatingsCollection(String hospitalKey) =>
      _firestore.collection('hospital_ratings').doc(hospitalKey).collection('ratings');

  static Future<List<HospitalRating>> getRatingsForHospital(String hospitalKey) async {
    if (_ratingsCache.containsKey(hospitalKey)) {
      return _ratingsCache[hospitalKey]!;
    }
    final snapshot = await _hospitalRatingsCollection(hospitalKey).get();
    final ratings = snapshot.docs.map((doc) => HospitalRating.fromJson(doc.data())).toList();
    _ratingsCache[hospitalKey] = ratings;
    return ratings;
  }

  static void cacheRatings(String hospitalKey, List<HospitalRating> ratings) {
    _ratingsCache[hospitalKey] = ratings;
  }

  static Future<void> submitRating(String hospitalKey, HospitalRating rating) async {
    await _hospitalRatingsCollection(hospitalKey).doc(rating.userId).set(rating.toJson());
    // Optionally, invalidate or update cache after submit
    _ratingsCache.remove(hospitalKey);
  }
} 