import 'dart:convert';

class Prescription {
  final String medicineName;
  final String dosage;
  final List<String> times; // e.g., ["08:00", "14:00", "20:00"]
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;

  Prescription({
    required this.medicineName,
    required this.dosage,
    required this.times,
    required this.startDate,
    this.endDate,
    this.instructions,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      medicineName: json['medicineName'],
      dosage: json['dosage'],
      times: List<String>.from(json['times'] ?? []),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
    };
  }

  static List<Prescription> listFromJson(String jsonString) {
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => Prescription.fromJson(e)).toList();
  }

  static String listToJson(List<Prescription> prescriptions) {
    final List<Map<String, dynamic>> encoded = prescriptions.map((e) => e.toJson()).toList();
    return json.encode(encoded);
  }
} 