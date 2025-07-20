import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoModel {
  final String name;
  final String? handle;
  final String? photoURL;
  final int? age;
  final int followersCount;
  final int followingCount;
  final List<Map<String, dynamic>> flairs;

  UserInfoModel({
    required this.name,
    this.handle,
    this.photoURL,
    this.age,
    this.followersCount = 0,
    this.followingCount = 0,
    this.flairs = const [],
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> data, {int followers = 0, int following = 0, List<Map<String, dynamic>> flairs = const []}) {
    return UserInfoModel(
      name: data['name'] ?? 'User',
      handle: data['handle'],
      photoURL: data['profilePicUrl'] ?? data['photoURL'],
      age: data['age'] is int ? data['age'] : int.tryParse(data['age']?.toString() ?? ''),
      followersCount: followers,
      followingCount: following,
      flairs: flairs,
    );
  }
}

class UserInfoNotifier extends StateNotifier<AsyncValue<UserInfoModel>> {
  UserInfoNotifier() : super(const AsyncValue.loading()) {
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = AsyncValue.error('No user logged in', StackTrace.current);
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        state = AsyncValue.error('No user data found', StackTrace.current);
        return;
      }
      // Fetch followers and following counts
      final followersSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('followers').get();
      final followingSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').get();
      final followersCount = followersSnapshot.docs.length;
      final followingCount = followingSnapshot.docs.length;
      // Fetch flairs subcollection
      final flairsSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('flairs').get();
      final flairs = flairsSnapshot.docs.map((d) => d.data()).toList();
      state = AsyncValue.data(
        UserInfoModel.fromMap(data, followers: followersCount, following: followingCount, flairs: flairs)
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'name': newName}, SetOptions(merge: true));
    await loadUserInfo();
  }
}

final userInfoProvider = StateNotifierProvider<UserInfoNotifier, AsyncValue<UserInfoModel>>((ref) {
  return UserInfoNotifier();
}); 