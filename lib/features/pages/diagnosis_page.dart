import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/secrets.dart';
import 'package:wellwiz/features/appointments/mhp_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/features/appointments/booking.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  List<Map<String, dynamic>> randomDoctors = [];
  List<Map<String, dynamic>> randomMHPs = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> doctorNames = ['Dr. Smith', 'Dr. Jane', 'Dr. Doe'];
  final List<IconData> doctorIcons = [Icons.person, Icons.person, Icons.person];
  Map<String, String> profileMap = {};
  List<List<dynamic>> tableList = [];
  List<List<dynamic>> prescriptionsList = [];
  bool emptyNow = false;
  String username = "";
  String userimg = "";
  late File _image;
  late final GenerativeModel _model;
  static const _apiKey = geminikey;
  late final ChatSession _chat;
  bool imageInitialized = false;
  bool _isTableExpanded = false;
  bool _isExpanded = false;
  bool _isPrescriptionsExpanded = false;

  final safetysettings = [
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ];

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
    _populateProfile();
    _getUserInfo();
    _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        safetySettings: safetysettings);
    _chat = _model.startChat();
    // Fetch random doctors and MHPs when the widget is initialized
    fetchRandomDoctors().then((docs) {
      setState(() {
        randomDoctors = docs;
      });
    });

    fetchRandomMHPs().then((mhps) {
      setState(() {
        randomMHPs = mhps;
      });
    });
  }

  // Function to fetch doctors from Firestore
  Future<List<Map<String, dynamic>>> fetchRandomDoctors() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('doctor').get();
    List<Map<String, dynamic>> doctors =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    doctors.shuffle(); // Shuffle the list to randomize the doctors
    return doctors.take(3).toList(); // Take only 3 random doctors
  }

  // Function to fetch MHPs from Firestore
  Future<List<Map<String, dynamic>>> fetchRandomMHPs() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('mhp').get();
    List<Map<String, dynamic>> mhps =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    mhps.shuffle(); // Shuffle the list to randomize the MHPs
    return mhps.take(3).toList(); // Take only 3 random MHPs
  }

  Future<void> getImageCamera(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Image Source",
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Permission.camera.request();
                  var image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Gallery",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  var image = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImageMessage() async {
    final imgBytes = await _image.readAsBytes();
    final SharedPreferences pref = await SharedPreferences.getInstance();

    String? tableJson = pref.getString("table");
    List<List<dynamic>> tableList = [];

    if (tableJson != null && tableJson.isNotEmpty) {
      try {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }

    Fluttertoast.showToast(msg: "Extracting information...");

    String prompt = """
  You are being used as a medical chatbot for demonstration purposes. 
  The user has submitted a medical report in image form, and you need to extract body chemical levels. 
  Here is the current table of body chemical levels stored as a JSON list: $tableList.

  Instructions:
  1. Extract the body chemical levels from the medical report and format them as "Title : Value : Integer" where:
    - "Title" is the name of the chemical or component. If it is written in short then write the full form or the more well-known version of that title.
    - "Value" is the numerical level.
    - "Integer" is 0, -1, or 1 depending on the following:
      - 0: Level is within the normal range
      - -1: Level is below the normal range
      - 1: Level is above the normal range

  2. Compare the extracted chemical levels against the provided table list. 
    - If a chemical level is missing from the table, or if its value has changed, return it in the response.
    - Only return those entries that either aren't found in the `tableList` or have updated values.

  Return the list of updated or new chemical levels in the format "Title : Value : Integer".
  If nothing is found, return "none".
  """;

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imgBytes),
      ])
    ];

    final response = await _model.generateContent(content);
    final responseText = response.text!.toLowerCase().trim();

    print("Response: $responseText");

    if (responseText == "none") {
      Fluttertoast.showToast(msg: "No new or updated levels found.");
      return;
    }

    try {
      List<String> entries =
          responseText.split('\n').map((e) => e.trim()).toList();

      for (var entry in entries) {
        List<String> parts = entry.split(':').map((e) => e.trim()).toList();

        if (parts.length == 3) {
          String title = parts[0];
          String value = parts[1];
          int flag = int.tryParse(parts[2]) ?? 0;

          bool found = false;
          for (var existingEntry in tableList) {
            if (existingEntry[0] == title) {
              if (existingEntry[1] != value || existingEntry[2] != flag) {
                existingEntry[1] = value;
                existingEntry[2] = flag;
                print("Updated entry: $existingEntry");
              }
              found = true;
              break;
            }
          }

          if (!found) {
            tableList.add([title, value, flag]);
            print("Added new entry: [${title}, ${value}, ${flag}]");
          }
        } else {
          print("Unexpected entry format: $entry");
        }
      }

      tableJson = jsonEncode(tableList);
      await pref.setString('table', tableJson);
      print("Updated tableList: $tableList");
      Fluttertoast.showToast(msg: "Updated levels added to table.");

      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "An unknown error occurred!");
      print("Error parsing response: $e");
    }
  }

  void _populateProfile() async {
    final pref = await SharedPreferences.getInstance();

    String prefval = pref.getString('prof') ?? "";
    if (prefval.isEmpty || prefval == "{}") {
      setState(() {
        emptyNow = true;
      });
    } else {
      setState(() {
        profileMap = Map<String, String>.from(jsonDecode(prefval));
      });
    }

    String? prescriptionsJson = pref.getString('prescriptions');
    if (prescriptionsJson != null && prescriptionsJson.isNotEmpty) {
      setState(() {
        prescriptionsList = List<List<dynamic>>.from(
            jsonDecode(prescriptionsJson)
                .map((item) => List<dynamic>.from(item)));
      });
    }

    String? tableJson = pref.getString('table');
    if (tableJson != null && tableJson.isNotEmpty) {
      setState(() {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      });
    }
  }

  void _deleteProfileValue(String key) async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      profileMap.remove(key);
    });
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
  }

  void _addProfileValue(String newValue) async {
    final pref = await SharedPreferences.getInstance();
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    setState(() {
      profileMap[currentDateTime] = newValue;
    });

    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
  }

  void _showAddProfileDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Profile Entry'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter profile detail'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addProfileValue(_controller.text);
                }
                setState(() {
                  emptyNow = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTableData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      tableList.clear();
    });
    await pref.remove('table');
  }

  void _deletePrescriptionData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      prescriptionsList.clear();
    });
    await pref.remove('prescriptions');
  }

  Widget _buildPrescriptionsTable() {
    if (prescriptionsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            textAlign: TextAlign.justify,
            'Tell WellWiz about your medicines!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }

    prescriptionsList.sort((a, b) => a[0].compareTo(b[0]));

    return Table(
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Medication',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Dosage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        ...prescriptionsList.map((row) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[0]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[1]),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Function to display section title
  Widget sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // Function to build a horizontal list view for doctors and MHPs
  Widget horizontalListView(
      List<Map<String, dynamic>> items, String type, VoidCallback onArrowTap) {
    return Container(
      height: 120,
      margin: EdgeInsets.only(right: 20, left: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1, // +1 for the arrow button
        itemBuilder: (context, index) {
          if (index < items.length) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                // Navigate to individual doctor's or MHP's page if needed
              },
              child: Container(
                width: 120, // Set a fixed width for uniform tile size
                padding: EdgeInsets.symmetric(
                    horizontal: 20), // Adjust padding as needed
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
              onTap: onArrowTap,
              child: Container(
                width: 50, // Keep the arrow button's size separate
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
    );
  }

  Widget _buildTable() {
    if (tableList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            'Try scanning some reports!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }

    tableList.sort((a, b) => a[0].compareTo(b[0]));

    return Table(
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Chemical',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Value',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        ...tableList.map((row) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[0]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[1]),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: () {
                  if (row[2] == 1) {
                    return const Icon(Icons.arrow_upward, color: Colors.red);
                  } else if (row[2] == -1) {
                    return const Icon(Icons.arrow_downward, color: Colors.red);
                  } else {
                    return const Icon(Icons.thumb_up_sharp,
                        color: Colors.green);
                  }
                }(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Check-",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromARGB(255, 106, 172, 67)),
              ),
              Text(
                "Ups",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        // Doctors Section
        sectionTitle("Our Doctors"),
        horizontalListView(randomDoctors, 'doctors', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DocView(userId: _auth.currentUser?.uid ?? '')),
          );
        }),
        // horizontalListView(
        //   randomDoctors, // List of doctor items
        //   'doctor', // or 'mhp' depending on the context
        //   _auth.currentUser?.uid ?? '', // The current user's ID
        //   true, // Set true if it's a doctor, false for MHP
        //   () {
        //     // Define the navigation function for the arrow button
        //     Navigator.push(context, MaterialPageRoute(builder: (context) => DocView(userId: _auth.currentUser?.uid ?? '')));
        //   },
        // ),

        // MHPs Section
        sectionTitle("Our MHPs"),
        horizontalListView(randomMHPs, 'mhp', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MhpView(userId: _auth.currentUser?.uid ?? '')),
          );
        }),
        // horizontalListView(
        //   randomMHPs, // List of doctor items
        //   'mhp', // or 'mhp' depending on the context
        //   _auth.currentUser?.uid ?? '', // The current user's ID
        //   false, // Set true if it's a doctor, false for MHP
        //   () {
        //     // Define the navigation function for the arrow button
        //     Navigator.push(context, MaterialPageRoute(builder: (context) => MhpView(userId: _auth.currentUser?.uid ?? '')));
        //   },
        // ),
        SizedBox(
          height: 20,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  color: Colors.grey.shade300,
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isTableExpanded
                                ? Icons.arrow_drop_down_rounded
                                : Icons.arrow_right_rounded,
                            color: Color.fromARGB(255, 96, 168, 82),
                          ),
                          onPressed: () {
                            setState(() {
                              _isTableExpanded = !_isTableExpanded;
                            });
                          },
                        ),
                        Text(
                          'Health Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.camera_alt,
                              color: Color.fromARGB(255, 96, 168, 82)),
                          onPressed: () {
                            getImageCamera(context);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Color.fromARGB(255, 96, 168, 82)),
                          onPressed: () {
                            _deleteTableData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isTableExpanded) _buildTable(),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  color: Colors.grey.shade300,
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            !_isPrescriptionsExpanded
                                ? Icons.arrow_right_rounded
                                : Icons.arrow_drop_down_rounded,
                            color: Color.fromARGB(255, 96, 168, 82),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPrescriptionsExpanded =
                                  !_isPrescriptionsExpanded;
                            });
                          },
                        ),
                        Text(
                          'Prescriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chat_outlined,
                              color: Color.fromARGB(255, 96, 168, 82)),
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return BotScreen();
                            }));
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Color.fromARGB(255, 96, 168, 82)),
                          onPressed: () {
                            _deletePrescriptionData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isPrescriptionsExpanded) _buildPrescriptionsTable(),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    color: Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              icon: Icon(
                                !_isExpanded
                                    ? Icons.arrow_right_rounded
                                    : Icons.arrow_drop_down_rounded,
                                color: Color.fromARGB(255, 96, 168, 82),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Your Traits',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_box_outlined,
                            color: Color.fromARGB(255, 96, 168, 82)),
                        onPressed: () {
                          _showAddProfileDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 15),
                  emptyNow
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green.shade100,
                          ),
                          child: const Center(
                            child: Text(
                              'Add something about yourself!',
                              style: TextStyle(fontFamily: 'Mulish'),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: profileMap.length,
                            itemBuilder: (context, index) {
                              String key = profileMap.keys.elementAt(index);
                              String value = profileMap[key]!;
                              String datePart = key.split(' ')[0];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 96, 168, 82),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Created on : $datePart",
                                              style: TextStyle(
                                                color: Colors.grey.shade100,
                                                fontFamily: 'Mulish',
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              value,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish',
                                                fontSize: 16,
                                              ),
                                              maxLines: null,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _deleteProfileValue(key);
                                          setState(() {
                                            _populateProfile();
                                          });
                                        },
                                        icon: Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  SizedBox(height: 15),
                ],
              ],
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
