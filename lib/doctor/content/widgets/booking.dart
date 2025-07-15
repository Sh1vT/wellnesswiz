import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
        DateTime? selectedDateTime;

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
                  _bookAppointment(context, entityId, userId, selectedDateTime!, isDoctor);
                } else {
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

  Future<void> _bookAppointment(
    BuildContext context, 
    String entityId, 
    String userId, 
    DateTime appointmentDateTime, 
    bool isDoctor
  ) async {
    DateTime startTime = appointmentDateTime;
    DateTime endTime = startTime.add(const Duration(hours: 1));
    String collectionName = isDoctor ? 'doctor' : 'mhp';
    CollectionReference appointments = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(entityId)
        .collection('Appointments');
    QuerySnapshot existingAppointments = await appointments
        .where('startTime', isLessThanOrEqualTo: endTime)
        .where('endTime', isGreaterThanOrEqualTo: startTime)
        .get();
    if (existingAppointments.docs.isNotEmpty) {
      _showToast('This time slot is already booked. Please choose another time.');
      return;
    }
    Map<String, dynamic> appointmentData = {
      'startTime': startTime,
      'endTime': endTime,
      'status': 'booked',
      'userId': userId,
    };
    try {
      await appointments.add(appointmentData);
      _showToast('Appointment booked with ${isDoctor ? 'doctor' : 'mental health professional'} on ${startTime.toString()}');
    } catch (e) {
      _showToast('Failed to book appointment: $e');
    }
  }

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