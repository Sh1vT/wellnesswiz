import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/appointments/app_page.dart'; // Import the UserAppointmentsPage
import 'doc_tile.dart'; // Update with the correct path to doc_tile.dart

class DocView extends StatefulWidget {
  final String userId;
  DocView({super.key, required this.userId});

  @override
  State<DocView> createState() => _DocViewState();
}

class _DocViewState extends State<DocView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20,)),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return UserAppointmentsPage(userId: widget.userId);
                  }));
                },
                icon: Icon(Icons.calendar_month),
              ),
              SizedBox(
                width: 10,
              )
            ],
          )
        ],
      ),
      
      body: SingleChildScrollView(
        // Make the body scrollable
        child: Column(
          children: [
            // Title section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Our",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: Color.fromRGBO(106, 172, 67, 1)),
                ),
                Text(
                  " Doctors",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: const Color.fromRGBO(97, 97, 97, 1)),
                ),
              ],
            ),
            SizedBox(height: 12),

            // StreamBuilder for the GridView
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('doctor').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading doctors"));
                }

                final List<Doctor> doctors = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Doctor.fromFirestore(
                      doc.id, data); // Pass the document ID
                }).toList();

                return GridView.builder(
                  physics:
                      NeverScrollableScrollPhysics(), // Disable GridView scrolling
                  shrinkWrap:
                      true, // Allow GridView to take the size of its content
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 tiles per row
                    mainAxisSpacing: 8, // Spacing between rows
                    crossAxisSpacing: 8, // Spacing between columns
                    childAspectRatio:
                        0.75, // Aspect ratio for tiles (width/height)
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return DoctorTile(
                      doctor: doctor,
                      userId: widget.userId,
                    ); // Pass userId here
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
