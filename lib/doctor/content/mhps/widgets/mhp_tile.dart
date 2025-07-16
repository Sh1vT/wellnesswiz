import 'package:flutter/material.dart';
import 'package:wellwiz/doctor/content/docs/widgets/booking.dart';

class MentalHealthProfessional {
  final String id;
  final String name;
  final String profession;
  final String imageUrl;

  MentalHealthProfessional({
    required this.id,
    required this.name,
    required this.profession,
    required this.imageUrl,
  });

  factory MentalHealthProfessional.fromFirestore(String id, Map<String, dynamic> data) {
    return MentalHealthProfessional(
      id: id,
      name: data['name'],
      profession: data['profession'],
      imageUrl: data['imageUrl'],
    );
  }
}

class MhpTile extends StatelessWidget {
  final MentalHealthProfessional mhp;
  final String userId;

  const MhpTile({super.key, required this.mhp, required this.userId});

  void _showMhpDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            mhp.name,
            style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade400, width: 3),
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(mhp.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Profession: ${mhp.profession}",
                style: TextStyle(fontFamily: 'Mulish'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final appointmentService = AppointmentService();
                Navigator.of(context).pop();
                await appointmentService.selectAndBookAppointment(context, mhp.id, userId, false);
              },
              child: Text(
                "Book Appointment",
                style: TextStyle(
                    fontFamily: 'Mulish',
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                    fontFamily: 'Mulish',
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMhpDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Spacer(),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Color.fromRGBO(70, 130, 180, 1), width: 3),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(mhp.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              mhp.name,
              style: TextStyle(
                  color: Color.fromRGBO(70, 130, 180, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish'),
              textAlign: TextAlign.center,
            ),
            Text(
              mhp.profession,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Mulish',
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
} 