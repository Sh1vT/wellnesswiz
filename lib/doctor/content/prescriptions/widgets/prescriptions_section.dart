import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/chat/content/bot/widgets/bot_screen.dart';
import 'package:wellwiz/doctor/content/prescriptions/models/prescription.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'dart:math' as math;
import 'package:wellwiz/doctor/content/prescriptions/widgets/medicine_card.dart';
import 'package:wellwiz/doctor/content/prescriptions/widgets/add_prescription_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/utils/reminder_utils.dart';

class PrescriptionsSection extends StatefulWidget {
  const PrescriptionsSection({super.key});

  @override
  State<PrescriptionsSection> createState() => _PrescriptionsSectionState();
}

class _PrescriptionsSectionState extends State<PrescriptionsSection> {
  List<Prescription> prescriptionsList = [];
  String selectedTimeOfDay = 'Morning';

  static const Map<String, List<String>> timeOfDayRanges = {
    'Morning': ['05:00', '11:59'],
    'Noon': ['12:00', '15:59'],
    'Evening': ['16:00', '19:59'],
    'Night': ['20:00', '04:59'],
  };

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final pref = await SharedPreferences.getInstance();
    String? prescriptionsJson = pref.getString('prescriptions');
    if (prescriptionsJson != null && prescriptionsJson.isNotEmpty) {
      setState(() {
        prescriptionsList = Prescription.listFromJson(prescriptionsJson);
      });
    } else {
      setState(() {
        prescriptionsList = [];
      });
    }
  }

  Future<void> _addPrescription(Prescription prescription) async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      prescriptionsList.add(prescription);
    });
    await pref.setString(
      'prescriptions',
      Prescription.listToJson(prescriptionsList),
    );

    // --- Reminder scheduling logic ---
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty && prescription.startDate != null) {
      for (final t in prescription.times) {
        final parts = t.split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        // Schedule for each day from startDate to endDate (or just startDate if endDate is null)
        final end = prescription.endDate ?? prescription.startDate;
        DateTime day = prescription.startDate;
        while (!day.isAfter(end)) {
          final scheduledTime = DateTime(
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          );
          if (scheduledTime.isAfter(DateTime.now())) {
            print(
              '[DEBUG] Scheduling reminder for user: $userId, med: ${prescription.medicineName}, time: $scheduledTime, dosage: ${prescription.dosage}, instructions: ${prescription.instructions}',
            );
            await createAndScheduleReminder(
              userId: userId,
              title: prescription.medicineName,
              description:
                  'Take ${prescription.dosage} tablet(s)' +
                  (prescription.instructions != null &&
                          prescription.instructions!.trim().isNotEmpty
                      ? '\nNote: ${prescription.instructions}'
                      : ''),
              scheduledTime: scheduledTime,
            );
          } else {
            print('[DEBUG] Skipping past reminder for $scheduledTime');
          }
          day = day.add(Duration(days: 1));
        }
      }
    }
    // --- End reminder scheduling logic ---
  }

  void _showAddPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPrescriptionDialog(
        onAdd: (prescription) async {
          await _addPrescription(prescription);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  List<Prescription> _filterByTimeOfDay(String timeOfDay) {
    final range = timeOfDayRanges[timeOfDay]!;
    final start = _parseTime(range[0]);
    final end = _parseTime(range[1]);
    return prescriptionsList.where((prescription) {
      return prescription.times.any((t) {
        final time = _parseTime(t);
        if (start.isBefore(end)) {
          return !time.isBefore(start) && !time.isAfter(end);
        } else {
          // Night: wraps around midnight
          return !time.isBefore(start) || !time.isAfter(end);
        }
      });
    }).toList();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Widget _buildTimeOfDayChips() {
    final times = timeOfDayRanges.keys.toList();
    // Determine which times have medicines
    final timesWithMeds = times
        .where((label) => _filterByTimeOfDay(label).isNotEmpty)
        .toList();
    final showAnyMeds = timesWithMeds.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 8,
              ), // Increased left padding
              child: ActionChip(
                avatar: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: ColorPalette.green,
                onPressed: _showAddPrescriptionDialog,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
            if (showAnyMeds)
              ...timesWithMeds.map(
                (label) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w600,
                        color: selectedTimeOfDay == label
                            ? Colors.white
                            : ColorPalette.black,
                      ),
                    ),
                    selected: selectedTimeOfDay == label,
                    selectedColor: ColorPalette.green,
                    backgroundColor: Colors.grey[200],
                    onSelected: (selected) {
                      setState(() {
                        if (selectedTimeOfDay == label) {
                          selectedTimeOfDay = '';
                        } else {
                          selectedTimeOfDay = label;
                        }
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to persist and retrieve taken meds
  Future<Map<String, dynamic>> _getTakenMeds() async {
    final pref = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = 'taken_meds_' + userId;
    final jsonStr = pref.getString(key);
    if (jsonStr == null) return {};
    return jsonDecode(jsonStr);
  }

  Future<void> _setTakenMed(
    String medName,
    String date,
    String time, {
    bool? value,
  }) async {
    final pref = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = 'taken_meds_' + userId;
    final taken = await _getTakenMeds();
    final takenKey = '$medName|$date|$time';
    if (value == false) {
      taken.remove(takenKey);
    } else {
      taken[takenKey] = true;
    }
    await pref.setString(key, jsonEncode(taken));
    setState(() {});
  }

  Future<void> _deletePrescriptionTimeSlot(
    Prescription prescription,
    String timeSlot,
  ) async {
    final pref = await SharedPreferences.getInstance();
    // Remove the time from the prescription
    final idx = prescriptionsList.indexWhere(
      (p) =>
          p.medicineName == prescription.medicineName &&
          p.startDate == prescription.startDate &&
          p.endDate == prescription.endDate,
    );
    if (idx != -1) {
      final updatedTimes = List<String>.from(prescriptionsList[idx].times);
      updatedTimes.remove(timeSlot);
      if (updatedTimes.isEmpty) {
        prescriptionsList.removeAt(idx);
      } else {
        prescriptionsList[idx] = Prescription(
          medicineName: prescription.medicineName,
          dosage: prescription.dosage,
          times: updatedTimes,
          startDate: prescription.startDate,
          endDate: prescription.endDate,
          instructions: prescription.instructions,
        );
      }
      await pref.setString(
        'prescriptions',
        Prescription.listToJson(prescriptionsList),
      );
    }
    // Remove all taken states for this medicine and time slot
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = 'taken_meds_' + userId;
    final taken = await _getTakenMeds();
    final keysToRemove = taken.keys
        .where(
          (k) =>
              k.startsWith('${prescription.medicineName}|') &&
              k.endsWith('|$timeSlot'),
        )
        .toList();
    for (final k in keysToRemove) {
      taken.remove(k);
    }
    await pref.setString(key, jsonEncode(taken));
    setState(() {});
  }

  Widget _buildMedicineCards() {
    final filtered = _filterByTimeOfDay(selectedTimeOfDay);
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: ColorPalette.greenSwatch[50],
          ),
          child: const Center(
            child: Text(
              'Add some of your meds!',
              style: TextStyle(fontFamily: 'Mulish', fontSize: 15, color: ColorPalette.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTakenMeds(),
      builder: (context, snapshot) {
        final taken = snapshot.data ?? {};
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Top align the cards
            children: List.generate(filtered.length, (idx) {
              final p = filtered[idx];
              final today = DateTime.now();
              final dateStr =
                  '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              final timesForWindow =
                  MedicineCard.timeOfDayRanges[selectedTimeOfDay] != null
                  ? MedicineCard(
                      prescription: p,
                      timeOfDay: selectedTimeOfDay,
                    ).getTimesForWindow()
                  : [];
              bool isTaken =
                  timesForWindow.isNotEmpty &&
                  timesForWindow.every(
                    (t) => taken['${p.medicineName}|$dateStr|$t'] == true,
                  );
              return Padding(
                padding: EdgeInsets.only(
                  right: idx == filtered.length - 1 ? 0 : 16,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: MedicineCard(
                    prescription: p,
                    timeOfDay: selectedTimeOfDay,
                    isTaken: isTaken,
                    onCheck: () async {
                      for (final t in timesForWindow) {
                        if (isTaken) {
                          await _setTakenMed(
                            p.medicineName,
                            dateStr,
                            t,
                            value: false,
                          );
                        } else {
                          await _setTakenMed(
                            p.medicineName,
                            dateStr,
                            t,
                            value: true,
                          );
                        }
                      }
                    },
                    onDelete: () async {
                      if (timesForWindow.isEmpty) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Time Slot'),
                          content: Text(
                            'Are you sure you want to delete the time slot ${timesForWindow.join(", ")} for ${p.medicineName}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: ColorPalette.black),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        for (final t in timesForWindow) {
                          await _deletePrescriptionTimeSlot(p, t);
                        }
                      }
                    },
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 0),
          child: Text(
            'Prescriptions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorPalette.black,
              fontFamily: 'Mulish',
            ),
          ),
        ),
        _buildTimeOfDayChips(),
        _buildMedicineCards(),
      ],
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final Color color;
  _HalfCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, math.pi / 2, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
