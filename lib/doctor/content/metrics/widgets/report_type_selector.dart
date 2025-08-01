import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class ReportTypeSelector extends StatelessWidget {
  final List<String> reportTypes;
  final String? selectedType;
  final ValueChanged<String> onSelected;
  final String customType;
  final ValueChanged<String> onCustomChanged;
  final TextEditingController? controller;

  const ReportTypeSelector({
    super.key,
    required this.reportTypes,
    required this.selectedType,
    required this.onSelected,
    required this.customType,
    required this.onCustomChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Type",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: reportTypes
              .map(
                (type) => ChoiceChip(
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: selectedType == type ? Colors.white : ColorPalette.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  selected: selectedType == type,
                  selectedColor: ColorPalette.green,
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide.none,
                  ),
                  elevation: 0,
                  onSelected: (selected) {
                    if (selected) onSelected(type);
                  },
                ),
              )
              .toList(),
        ),
        if (selectedType == 'Custom')
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: TextField(
              onChanged: onCustomChanged,
              decoration: InputDecoration(
                labelText: "Enter custom snap type",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorPalette.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorPalette.greenSwatch[100]!, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              controller: controller,
            ),
          ),
      ],
    );
  }
} 