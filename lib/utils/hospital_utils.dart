import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_geohash/dart_geohash.dart';

class Hospital {
  final String name;
  final double latitude;
  final double longitude;
  final String geohash4;
  final String geohash5;
  final String geohash6;
  final Map<String, dynamic> raw;

  Hospital({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.geohash4,
    required this.geohash5,
    required this.geohash6,
    required this.raw,
  });
}

Future<List<Hospital>> fetchNearbyHospitals({
  required double userLat,
  required double userLng,
  int geohashPrecision = 5,
  int maxResults = 20,
}) async {
  final csvString = await rootBundle.loadString('assets/data/hospital_with_coords_geohash.csv');
  final csvRows = const CsvToListConverter(eol: '\n').convert(csvString);
  if (csvRows.isEmpty) return [];
  final headers = csvRows.first.map((e) => e.toString()).toList();
  final locCol = headers.indexOf('Location_Coordinates');
  final nameCol = headers.indexOf('Hospital_Name');
  final geohashCol = 'GeoHash_$geohashPrecision';
  final geohashColIdx = headers.indexOf(geohashCol);

  final geoHasher = GeoHasher();
  // NOTE: Swapping lat/lng due to dart_geohash argument order issue
  final userGeohash = geoHasher.encode(userLng, userLat, precision: geohashPrecision);

  List<Hospital> hospitals = [];
  for (var i = 1; i < csvRows.length; i++) {
    final row = csvRows[i];
    final coords = (row[locCol]?.toString() ?? '').split(',');
    final latitude = coords.length == 2 ? double.tryParse(coords[0].trim()) ?? 0.0 : 0.0;
    final longitude = coords.length == 2 ? double.tryParse(coords[1].trim()) ?? 0.0 : 0.0;
    final rowGeohash = row[geohashColIdx]?.toString().trim();
    if (rowGeohash == userGeohash) {
      hospitals.add(Hospital(
        name: row[nameCol]?.toString() ?? '',
        latitude: latitude,
        longitude: longitude,
        geohash4: row[headers.indexOf('GeoHash_4')]?.toString() ?? '',
        geohash5: row[headers.indexOf('GeoHash_5')]?.toString() ?? '',
        geohash6: row[headers.indexOf('GeoHash_6')]?.toString() ?? '',
        raw: Map.fromIterables(headers, row),
      ));
    }
  }
  hospitals.sort((a, b) => _distance(userLat, userLng, a.latitude, a.longitude)
      .compareTo(_distance(userLat, userLng, b.latitude, b.longitude)));
  return hospitals.take(maxResults).toList();
}

/// Fetches nearby doctors (currently returns nearby hospitals as placeholders).
Future<List<Hospital>> fetchNearbyDoctors({
  required double userLat,
  required double userLng,
  int geohashPrecision = 5,
  int maxResults = 20,
}) async {
  // In the future, filter for doctors or doctor-specific data if available.
  return fetchNearbyHospitals(
    userLat: userLat,
    userLng: userLng,
    geohashPrecision: geohashPrecision,
    maxResults: maxResults,
  );
}

double _distance(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371; // km
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          (sin(dLng / 2) * sin(dLng / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0); 