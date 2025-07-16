import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/doctor/content/docs/widgets/app_page.dart';
import 'package:wellwiz/doctor/content/mhps/widgets/mhp_tile.dart';

class MhpView extends StatefulWidget {
  final String userId;
  MhpView({super.key, required this.userId});

  @override
  State<MhpView> createState() => _MhpViewState();
}

class _MhpViewState extends State<MhpView> {
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
        child: Column(
          children: [
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
                  " Professionals",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: const Color.fromRGBO(97, 97, 97, 1)),
                ),
              ],
            ),
            SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('mhp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading professionals"));
                }

                final List<MentalHealthProfessional> mhps = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return MentalHealthProfessional.fromFirestore(
                      doc.id, data);
                }).toList();

                return GridView.builder(
                  physics:
                      NeverScrollableScrollPhysics(),
                  shrinkWrap:
                      true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio:
                        0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: mhps.length,
                  itemBuilder: (context, index) {
                    final mhp = mhps[index];
                    return MhpTile(
                      mhp: mhp,
                      userId: widget.userId,
                    );
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