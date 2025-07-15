import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/doctor/content/widgets/doc_view.dart';

class DoctorsSection extends StatefulWidget {
  const DoctorsSection({super.key});

  @override
  State<DoctorsSection> createState() => _DoctorsSectionState();
}

class _DoctorsSectionState extends State<DoctorsSection> {
  List<Map<String, dynamic>> randomDoctors = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchRandomDoctors().then((docs) {
      setState(() {
        randomDoctors = docs;
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchRandomDoctors() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('doctor').get();
    List<Map<String, dynamic>> doctors =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    doctors.shuffle();
    return doctors.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          child: Text(
            'Our Doctors',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          height: 120,
          margin: EdgeInsets.only(right: 20, left: 15),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: randomDoctors.length + 1,
            itemBuilder: (context, index) {
              if (index < randomDoctors.length) {
                final item = randomDoctors[index];
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 120,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(item['imageUrl']),
                            radius: 20,
                          ),
                          SizedBox(height: 10),
                          Text(
                            item['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocView(userId: _auth.currentUser?.uid ?? ''),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward,
                            size: 24,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
} 