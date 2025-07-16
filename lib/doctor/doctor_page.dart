import 'package:flutter/material.dart';
import 'package:wellwiz/doctor/content/docs/widgets/checkups_title.dart';
import 'package:wellwiz/doctor/content/docs/widgets/doctors_section.dart';
import 'package:wellwiz/doctor/content/metrics/widgets/health_metrics_section.dart';
import 'package:wellwiz/doctor/content/mhps/widgets/mhps_section.dart';
import 'package:wellwiz/doctor/content/prescriptions/widgets/prescriptions_section.dart';
import 'package:wellwiz/doctor/content/traits/widgets/traits_section.dart';

class DoctorPage extends StatelessWidget {
  const DoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        CheckupsTitle(),
        SizedBox(height: 20),
        DoctorsSection(),
        MhpsSection(),
        SizedBox(height: 20),
        HealthMetricsSection(),
        SizedBox(height: 20),
        PrescriptionsSection(),
        SizedBox(height: 20),
        TraitsSection(),
      ],
    );
  }
}
