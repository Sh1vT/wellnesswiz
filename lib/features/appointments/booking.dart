import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import the fluttertoast package

class AppointmentService {
  Future<void> selectAndBookAppointment(
    BuildContext context, 
    String entityId, 
    String userId, 
    bool isDoctor
  ) async {
    final format = DateFormat("yyyy-MM-dd HH:mm");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? selectedDateTime; // Track the selected date and time

        return AlertDialog(
          title: const Text('Select Date and Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DateTimeField(
                format: format,
                decoration: const InputDecoration(
                  labelText: 'Select Date and Time',
                ),
                onShowPicker: (context, currentValue) {
                  return showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    initialDate: currentValue ?? DateTime.now(),
                    lastDate: DateTime(2101),
                  ).then((date) {
                    if (date != null) {
                      return showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                      ).then((time) {
                        if (time != null) {
                          selectedDateTime = DateTimeField.combine(date, time);
                          return selectedDateTime;
                        } else {
                          return currentValue;
                        }
                      });
                    } else {
                      return currentValue;
                    }
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (selectedDateTime != null) {
                  Navigator.of(context).pop();
                  // Call the booking method with selected date and time
                  _bookAppointment(context, entityId, userId, selectedDateTime!, isDoctor);
                } else {
                  // Handle case when date is not selected
                  _showToast('Please select a date and time.');
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to book and save appointment
  Future<void> _bookAppointment(
    BuildContext context, 
    String entityId, 
    String userId, 
    DateTime appointmentDateTime, 
    bool isDoctor
  ) async {
    DateTime startTime = appointmentDateTime;
    DateTime endTime = startTime.add(const Duration(hours: 1)); // Assume the appointment lasts 1 hour

    // Determine the correct collection based on whether it's a doctor or an MHP
    String collectionName = isDoctor ? 'doctor' : 'mhp';

    // Reference to the specific entity's "Appointments" subcollection
    CollectionReference appointments = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(entityId)
        .collection('Appointments');

    // Check for overlapping appointments
    QuerySnapshot existingAppointments = await appointments
        .where('startTime', isLessThanOrEqualTo: endTime)
        .where('endTime', isGreaterThanOrEqualTo: startTime)
        .get();

    if (existingAppointments.docs.isNotEmpty) {
      // Inform the user that the time slot is already booked
      _showToast('This time slot is already booked. Please choose another time.');
      return; // Exit the function without saving the appointment
    }

    // If no overlapping appointments, proceed with saving the appointment
    Map<String, dynamic> appointmentData = {
      'startTime': startTime,
      'endTime': endTime,
      'status': 'booked', // Set status to booked
      'userId': userId,
    };

    try {
      await appointments.add(appointmentData);
      // Notify the user that the appointment was successfully booked
      _showToast('Appointment booked with ${isDoctor ? 'doctor' : 'mental health professional'} on ${startTime.toString()}');
    } catch (e) {
      // Handle any exceptions and inform the user
      _showToast('Failed to book appointment: $e');
    }
  }

  // Method to show a toast
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }
}
