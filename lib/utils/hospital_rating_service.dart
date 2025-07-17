import 'package:cloud_firestore/cloud_firestore.dart';
import '../doctor/content/docs/models/hospital_rating.dart';

class HospitalRatingService {
  static final _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> _hospitalRatingsCollection(String hospitalKey) =>
      _firestore.collection('hospital_ratings').doc(hospitalKey).collection('ratings');

  static Future<List<HospitalRating>> getRatingsForHospital(String hospitalKey) async {
    final snapshot = await _hospitalRatingsCollection(hospitalKey).get();
    return snapshot.docs.map((doc) => HospitalRating.fromJson(doc.data())).toList();
  }

  static Future<void> submitRating(String hospitalKey, HospitalRating rating) async {
    await _hospitalRatingsCollection(hospitalKey).doc(rating.userId).set(rating.toJson());
  }
} 