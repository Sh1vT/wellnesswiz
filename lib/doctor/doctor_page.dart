import 'package:flutter/material.dart';
import 'package:wellwiz/doctor/content/docs/widgets/checkups_title.dart';
import 'package:wellwiz/doctor/content/docs/widgets/doctors_section.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/health_metrics_section.dart';
// import 'package:wellwiz/doctor/content/mhps/widgets/mhps_section.dart';
import 'package:wellwiz/doctor/content/prescriptions/widgets/prescriptions_section.dart';
import 'package:wellwiz/doctor/content/traits/widgets/traits_section.dart';
import 'package:wellwiz/utils/hospital_utils.dart';

class DoctorPage extends StatefulWidget {
  static List<Hospital> hospitals20km = [];
  static List<Hospital> hospitals5km = [];
  static List<Hospital> hospitals1km = [];

  const DoctorPage({super.key});

  static void setupHospitals({
    required List<Hospital> within20km,
    required List<Hospital> within5km,
    required List<Hospital> within1km,
  }) {
    hospitals20km = within20km;
    hospitals5km = within5km;
    hospitals1km = within1km;
  }

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const CheckupsTitle(),
        const SizedBox(height: 20),
        NearbyHospitalsSection(
          within20km: DoctorPage.hospitals20km,
          within5km: DoctorPage.hospitals5km,
          within1km: DoctorPage.hospitals1km,
        ),
        // const MhpsSection(), // Commented out as requested
        // const SizedBox(height: 20),
        const HealthMetricsSection(),
        const SizedBox(height: 20),
        const PrescriptionsSection(),
        const SizedBox(height: 20),
        const TraitsSection(),
        const SizedBox(height: 20),
      ],
    );
  }
}
