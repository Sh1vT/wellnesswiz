import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoCache {
  static Map<String, dynamic>? _userInfo;

  static Future<Map<String, dynamic>?> getUserInfo() async {
    if (_userInfo != null) return _userInfo;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return null;
    // Fetch flairs subcollection
    final flairsSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('flairs').get();
    final flairs = flairsSnapshot.docs.map((d) => d.data()).toList();
    _userInfo = {
      ...data,
      'flairs': flairs,
      'profilePicUrl': data['profilePicUrl'] ?? data['photoURL'],
    };
    return _userInfo;
  }

  static void setUserInfo(Map<String, dynamic> info) {
    _userInfo = info;
  }

  static void clear() {
    _userInfo = null;
  }
} 