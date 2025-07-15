import 'package:flutter/material.dart';
import 'content/widgets/checkups_title.dart';
import 'content/widgets/doctors_section.dart';
import 'content/widgets/mhps_section.dart';
import 'content/widgets/health_metrics_section.dart';
import 'content/widgets/prescriptions_section.dart';
import 'content/widgets/traits_section.dart';

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
