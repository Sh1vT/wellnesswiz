import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wellwiz/chat/content/alerts/widgets/emergency_service.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:wellwiz/utils/poppy_tile.dart';

class SOSContactsButton extends StatelessWidget {
  const SOSContactsButton({super.key});

  Future<bool> _ensureLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Needed'),
          content: const Text('Location access is required to view and manage your SOS contacts.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: PoppyTile(
        borderRadius: 12,
        backgroundColor: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.all(20),
        onTap: () async {
          if (await _ensureLocationPermission(context)) {
            await Future.delayed(const Duration(milliseconds: 250));
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const EmergencyScreen();
            }));
          }
        },
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              size: 40,
              color: ColorPalette.green,
            ),
            const SizedBox(
              width: 20,
            ),
            Row(
              children: [
                Text(
                  'SOS ',
                  style: TextStyle(
                      color: Color.fromARGB(255, 106, 172, 67),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Mulish'),
                ),
                Text('Contacts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 18,
                        fontFamily: 'Mulish')),
              ],
            ),
            Spacer(),
            const Icon(
              Icons.navigate_next_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 