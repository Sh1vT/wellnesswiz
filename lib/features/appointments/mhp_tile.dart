import 'package:flutter/material.dart';
import 'booking.dart';

class MentalHealthProfessional {
  final String id; // Add MHP ID field
  final String name;
  final String profession;
  final String imageUrl;

  MentalHealthProfessional({
    required this.id, // Include ID in constructor
    required this.name,
    required this.profession,
    required this.imageUrl,
  });

  factory MentalHealthProfessional.fromFirestore(String id, Map<String, dynamic> data) {
    return MentalHealthProfessional(
      id: id, // Set ID from Firestore document
      name: data['name'],
      profession: data['profession'],
      imageUrl: data['imageUrl'],
    );
  }
}

class MhpTile extends StatelessWidget {
  final MentalHealthProfessional mhp;
  final String userId; // Add userId parameter

  const MhpTile({super.key, required this.mhp, required this.userId}); // Accept userId in the constructor

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
                // Call the booking method when 'Book Appointment' is clicked
                final appointmentService = AppointmentService();
                Navigator.of(context).pop(); // Close the dialog first
                // For booking a mental health professional
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
                Navigator.of(context).pop(); // Close the dialog
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
            // MHP's name
            Text(
              mhp.name,
              style: TextStyle(
                  color: Color.fromRGBO(70, 130, 180, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish'),
              textAlign: TextAlign.center,
            ),
            // MHP's profession
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
