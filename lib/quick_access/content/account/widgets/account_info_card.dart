import 'package:flutter/material.dart';
import 'package:wellwiz/providers/user_info_provider.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountInfoCard extends StatelessWidget {
  final String? name;
  final String? handle;
  final String? photoURL;
  final int? age;
  final int? followers;
  final int? following;
  final List<Map<String, dynamic>>? flairs;
  final WidgetRef ref;
  const AccountInfoCard({Key? key, this.name, this.handle, this.photoURL, this.age, this.followers, this.following, this.flairs, required this.ref}) : super(key: key);

  Color? _parseFlairColor(dynamic colorField) {
    if (colorField is String && colorField.startsWith('#') && (colorField.length == 7 || colorField.length == 9)) {
      try {
        return Color(int.parse(colorField.substring(1), radix: 16) + (colorField.length == 7 ? 0xFF000000 : 0));
      } catch (_) {}
    }
    return null;
  }

  void _showUserListSheet(BuildContext context, String type, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(type)
        .get();
    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        users.add({
          'uid': doc.id,
          'name': data['name'] ?? '',
          'handle': data['handle'] ?? '',
          'photoURL': data['photoURL'] ?? '',
        });
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        // Use a local list for immediate UI update
        List<Map<String, dynamic>> localUsers = List.from(users);
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                minWidth: double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(title, style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  if (localUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: const Center(
                          child: Text('No users found', style: TextStyle(fontFamily: 'Mulish')),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: localUsers.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, i) {
                          final userData = localUsers[i];
                          return ListTile(
                            leading: userData['photoURL'].isNotEmpty
                                ? CircleAvatar(backgroundImage: NetworkImage(userData['photoURL']))
                                : const CircleAvatar(child: Icon(Icons.account_circle)),
                            title: Text(userData['name'], style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
                            subtitle: Text('@${userData['handle']}', style: TextStyle(fontFamily: 'Mulish', color: Colors.grey.shade700)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: type == 'followers' ? 'Remove follower' : 'Unfollow',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey.shade50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: Text(
                                      type == 'followers' ? 'Remove Follower?' : 'Unfollow User?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey.shade700,
                                        fontFamily: 'Mulish',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Text(
                                      type == 'followers'
                                          ? "Are you sure you want to remove ${userData['name']} (@${userData['handle']}) from your followers?"
                                          : "Are you sure you want to unfollow ${userData['name']} (@${userData['handle']})?",
                                      style: const TextStyle(fontFamily: 'Mulish'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish')),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: Color.fromARGB(255, 106, 172, 67),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Remove', style: TextStyle(color: Colors.white, fontFamily: 'Mulish')),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) return;
                                  if (type == 'followers') {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .collection('followers')
                                        .doc(userData['uid'])
                                        .delete();
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userData['uid'])
                                        .collection('following')
                                        .doc(currentUser.uid)
                                        .delete();
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .collection('following')
                                        .doc(userData['uid'])
                                        .delete();
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userData['uid'])
                                        .collection('followers')
                                        .doc(currentUser.uid)
                                        .delete();
                                  }
                                  setModalState(() {
                                    localUsers.removeAt(i);
                                  });
                                  ref.read(userInfoProvider.notifier).loadUserInfo();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [ColorPalette.black, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.fromRGBO(106, 172, 67, 1),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
                                child: photoURL == null
                                    ? const Icon(Icons.account_circle, size: 38, color: Colors.grey)
                                    : null,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name ?? 'No name',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Mulish',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (handle != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.32),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '@$handle',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: ColorPalette.blackDarker,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Mulish',
                                            ),
                                          ),
                                        ),
                                      if (age != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.32),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '$age',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: ColorPalette.blackDarker,
                                              fontFamily: 'Mulish',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (followers != null)
                                TextButton(
                                  onPressed: () => _showUserListSheet(context, 'followers', 'Followers'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: ColorPalette.green.withOpacity(0.13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$followers', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 13, color: ColorPalette.green)),
                                      SizedBox(width: 6),
                                      Text('Followers', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 11, color: ColorPalette.green)),
                                    ],
                                  ),
                                ),
                              if (followers != null && following != null)
                                SizedBox(height: 6),
                              if (following != null)
                                TextButton(
                                  onPressed: () => _showUserListSheet(context, 'following', 'Following'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: ColorPalette.green.withOpacity(0.13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$following', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 13, color: ColorPalette.green)),
                                      SizedBox(width: 6),
                                      Text('Following', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 11, color: ColorPalette.green)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (flairs != null && flairs!.isNotEmpty)
              Positioned(
                right: 0,
                top: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < flairs!.length; i++) ...[
                      _FlagBadge(
                        text: flairs![i]['label'] ?? 'Flair',
                        color: _parseFlairColor(flairs![i]['color']) ?? Colors.deepPurpleAccent,
                        height: 24,
                      ),
                    ],
                  ],
                ),
              ),
            Positioned(
              right: 22,
              bottom: 24,
              child: Text(
                'WellWiz',
                style: TextStyle(
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double height;
  final EdgeInsetsGeometry padding;
  const _FlagBadge({
    required this.text,
    required this.color,
    this.height = 24,
    this.padding = const EdgeInsets.fromLTRB(22, 4, 16, 4), // More left padding for visual centering
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _FlagClipper(),
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.55), // stronger opacity for more glow
              blurRadius: 18, // larger blur for a more prominent glow
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: ColorPalette.blackDarker,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mulish',
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FlagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.height / 2, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.height / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
