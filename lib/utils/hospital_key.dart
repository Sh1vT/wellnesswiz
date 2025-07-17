import 'package:wellwiz/utils/hospital_utils.dart';

String generateHospitalKey(Hospital hospital) {
  return '${hospital.name}_${hospital.raw['District']}_${hospital.latitude}_${hospital.longitude}'
      .replaceAll(' ', '_')
      .replaceAll('.', '_')
      .toLowerCase();
} 