import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:wellwiz/doctor/content/widgets/doc_view.dart';

class UserAppointmentsPage extends StatefulWidget {
  final String userId;

  const UserAppointmentsPage({super.key, required this.userId});

  @override
  State<UserAppointmentsPage> createState() => _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends State<UserAppointmentsPage> {
  Future<void> _deleteAppointment(String entityType, String entityId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection(entityType)
          .doc(entityId)
          .collection('Appointments')
          .doc(appointmentId)
          .delete();
      Fluttertoast.showToast(msg: 'Appointment deleted successfully.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting appointment: $e');
    }
  }

  Future<String> _getEntityName(String entityId, String entityType) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(entityType)
          .doc(entityId)
          .get();
      return doc['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.grey.shade700,
              size: 18,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => DocView(userId: widget.userId)),
              );
            }),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "My",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: Color.fromRGBO(106, 172, 67, 1),
                ),
              ),
              Text(
                " Bookings",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  fontSize: 40,
                  color: const Color.fromRGBO(97, 97, 97, 1),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('Appointments')
                .where('userId', isEqualTo: widget.userId)
                .where('startTime', isGreaterThan: DateTime.now())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
          
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading appointments.'));
              }
          
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.shade100,
                  ),
                  child: const Center(
                    child: Text(
                      'No future appointments found.',
                      style: TextStyle(fontFamily: 'Mulish'),
                    ),
                  ),
                );
              }
          
              final appointments = snapshot.data!.docs;
          
              return Expanded(
                child: ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final data = appointment.data() as Map<String, dynamic>;
                          
                    final startTime = (data['startTime'] as Timestamp).toDate();
                    final endTime = (data['endTime'] as Timestamp).toDate();
                    final status = data['status'];
                    final entityId = appointment.reference.parent.parent!.id;
                    final appointmentId = appointment.id;

                    final entityType = appointment.reference.parent.parent!.parent.id == 'doctor'
                        ? 'doctor'
                        : 'mhp';

                    return FutureBuilder<String>(
                      future: _getEntityName(entityId, entityType),
                      builder: (context, entitySnapshot) {
                        if (entitySnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        }

                        if (entitySnapshot.hasError) {
                          return const ListTile(
                            title: Text('Error loading entity information'),
                          );
                        }

                        final entityName = entitySnapshot.data ?? 'Unknown';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _deleteAppointment(entityType, entityId, appointmentId);
                                },
                              ),
                              leading: Icon(
                                Icons.calendar_today,
                                size: 30,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appointment on ${DateFormat.yMMMd().add_jm().format(startTime)}',
                                    style: const TextStyle(
                                      fontFamily: 'Mulish',
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Status: ",
                                        style: TextStyle(
                                            color: Color.fromRGBO(106, 172, 67, 1),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        status,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "With: ",
                                        style: TextStyle(
                                            color: Color.fromRGBO(106, 172, 67, 1),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        entityName,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 