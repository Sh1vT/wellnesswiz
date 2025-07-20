import 'package:flutter/material.dart';
import 'package:wellwiz/doctor/content/prescriptions/models/prescription.dart';
import 'package:wellwiz/utils/color_palette.dart';

class AddPrescriptionDialog extends StatefulWidget {
  final Function(Prescription) onAdd;
  const AddPrescriptionDialog({required this.onAdd, super.key});

  @override
  State<AddPrescriptionDialog> createState() => _AddPrescriptionDialogState();
}

class _AddPrescriptionDialogState extends State<AddPrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  String medicineName = '';
  String dosage = '';
  List<String> times = [];
  DateTime? startDate;
  DateTime? endDate;
  String? instructions;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!times.contains(formatted)) {
        setState(() {
          times.add(formatted);
          times.sort();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.98;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text('Add Prescription', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Medicine name
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 0),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Name'),
                            onChanged: (val) => medicineName = val,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dosage
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 0),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Tablets'),
                            onChanged: (val) => dosage = val,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Times (as chips)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('Time', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ...times.map((t) => Chip(
                                        label: Text(t),
                                        backgroundColor: Colors.grey.shade200,
                                        deleteIcon: Icon(Icons.close, size: 16),
                                        onDeleted: () {
                                          setState(() {
                                            times.remove(t);
                                          });
                                        },
                                      )),
                                  ActionChip(
                                    avatar: Icon(Icons.add, size: 18, color: Colors.white),
                                    label: Text('Add', style: TextStyle(color: Colors.white)),
                                    backgroundColor: ColorPalette.green,
                                    onPressed: _pickTime,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 0),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Note'),
                            onChanged: (val) => instructions = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date pickers
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(startDate == null ? 'Start Date' : startDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => startDate = picked);
                          },
                          child: Text('Pick'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(endDate == null ? 'End Date (optional)' : endDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => endDate = picked);
                          },
                          child: Text('Pick'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ColorPalette.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: ColorPalette.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate() && startDate != null) {
              widget.onAdd(Prescription(
                medicineName: medicineName,
                dosage: dosage,
                times: times,
                startDate: startDate!,
                endDate: endDate,
                instructions: instructions,
              ));
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
} 