import 'package:flutter/material.dart';
import 'booking.dart';

class Doctor {
  final String id; // Add doctor ID field
  final String name;
  final String speciality;
  final String degree;
  final String imageUrl;

  Doctor({
    required this.id, // Include ID in constructor
    required this.name,
    required this.speciality,
    required this.degree,
    required this.imageUrl,
  });

  factory Doctor.fromFirestore(String id, Map<String, dynamic> data) {
    return Doctor(
      id: id, // Set ID from Firestore document
      name: data['name'],
      speciality: data['speciality'],
      degree: data['degree'],
      imageUrl: data['imageUrl'],
    );
  }
}

class DoctorTile extends StatelessWidget {
  final Doctor doctor;
  final String userId; // Add userId parameter

  const DoctorTile(
      {super.key,
      required this.doctor,
      required this.userId}); // Accept userId in the constructor

  void _showDoctorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            doctor.name,
            style: TextStyle(
                color: Colors.green.shade600,
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
                  border: Border.all(color: Colors.green.shade400, width: 3),
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(doctor.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Speciality: ${doctor.speciality}",
                style: TextStyle(fontFamily: 'Mulish'),
              ),
              Text(
                "Degree: ${doctor.degree}",
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
                // For booking a doctor
                await appointmentService.selectAndBookAppointment(context, doctor.id, userId, true);
              },
              child: Text(
                "Book Appointment",
                style: TextStyle(
                    fontFamily: 'Mulish',
                    color: Colors.green.shade600,
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
      onTap: () => _showDoctorDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          // border: Border.all(color: Colors.green.shade700, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Spacer(),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Color.fromRGBO(106, 172, 67, 1), width: 3),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(doctor.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            // Doctor's name
            Text(
              doctor.name,
              style: TextStyle(
                  color: Color.fromRGBO(106, 172, 67, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish'),
              textAlign: TextAlign.center,
            ),
            // Doctor's specialty
            Text(
              doctor.speciality,
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
