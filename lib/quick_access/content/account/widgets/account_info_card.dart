import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/utils/color_palette.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wellwiz/utils/user_info_cache.dart';

class AccountInfoCard extends StatefulWidget {
  const AccountInfoCard({Key? key}) : super(key: key);

  @override
  State<AccountInfoCard> createState() => _AccountInfoCardState();
}

class _AccountInfoCardState extends State<AccountInfoCard> {
  String? _handle;
  String? _displayName;
  String? _photoURL;
  int? _age;
  List<Map<String, dynamic>> _flairs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final cached = await UserInfoCache.getUserInfo();
    if (cached != null) {
      setState(() {
        _handle = cached['handle'];
        _displayName = cached['displayName'];
        _photoURL = cached['profilePicUrl'] ?? cached['photoURL'];
        _age = cached['age'] is int ? cached['age'] : int.tryParse(cached['age']?.toString() ?? '');
        _flairs = (cached['flairs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      UserInfoCache.setUserInfo(data);
      setState(() {
        _handle = data['handle'];
        _displayName = data['displayName'];
        _photoURL = data['profilePicUrl'] ?? data['photoURL'];
        _age = data['age'] is int ? data['age'] : int.tryParse(data['age']?.toString() ?? '');
        _flairs = (data['flairs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final TextEditingController nameController = TextEditingController(
      text: user.displayName ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Edit Display Name',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey.shade700,
            fontFamily: 'Mulish',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Display Name'),
          style: const TextStyle(fontFamily: 'Mulish'),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Color.fromARGB(255, 106, 172, 67),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontFamily: 'Mulish'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != user.displayName) {
      await user.updateDisplayName(result);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': result,
      }, SetOptions(merge: true));
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Display name updated!')));
    }
  }

  void _showUserListSheet(String type, String title) async {
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
          'displayName': data['displayName'] ?? '',
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
      builder: (context) => SafeArea(
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontFamily: 'Mulish'),
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, i) {
                      final userData = users[i];
                      return ListTile(
                        leading: userData['photoURL'].isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  userData['photoURL'],
                                ),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.account_circle),
                              ),
                        title: Text(
                          userData['displayName'],
                          style: const TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '@${userData['handle']}',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: type == 'followers'
                              ? 'Remove follower'
                              : 'Unfollow',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: Text(
                                  type == 'followers'
                                      ? 'Remove Follower?'
                                      : 'Unfollow User?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'Mulish',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  type == 'followers'
                                      ? "Are you sure you want to remove \${userData['displayName']} (@\${userData['handle']}) from your followers?"
                                      : "Are you sure you want to unfollow \${userData['displayName']} (@\${userData['handle']})?",
                                  style: const TextStyle(fontFamily: 'Mulish'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontFamily: 'Mulish'),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        106,
                                        172,
                                        67,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
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
                              Navigator.of(context).pop();
                              setState(() {});
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
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Mulish',
          fontSize: 13,
        ),
      ),
    );
  }

  Color? _parseFlairColor(dynamic colorField) {
    if (colorField is String && colorField.startsWith('#') && (colorField.length == 7 || colorField.length == 9)) {
      try {
        return Color(int.parse(colorField.substring(1), radix: 16) + (colorField.length == 7 ? 0xFF000000 : 0));
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (_isLoading) {
      // Shimmer skeleton placeholder
      return Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade800,
            highlightColor: Colors.grey.shade600,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar shimmer
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name, handle, age shimmer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 20,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  height: 16,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 16,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 24,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (user == null) {
      return const Center(
        child: Text(
          'No user signed in.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
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
            // Main content with padding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Existing content (as a Column)
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
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
                                backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                                child: _photoURL == null
                                    ? const Icon(Icons.account_circle, size: 38, color: Colors.grey)
                                    : null,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name, handle, age
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName ?? 'No display name',
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
                                      if (_handle != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.32),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '@$_handle',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: ColorPalette.blackDarker,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Mulish',
                                            ),
                                          ),
                                        ),
                                      if (_age != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.32),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '$_age',
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
                        // Stats row
                        Spacer(),
                        Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showUserListSheet('followers', 'Followers'),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.24,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(106, 172, 67, 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        FutureBuilder(
                                          future: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('followers').get(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 13, color: Color.fromRGBO(106, 172, 67, 1)));
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('Followers', style: TextStyle(fontFamily: 'Mulish', fontSize: 11, color: Color.fromRGBO(106, 172, 67, 1))),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showUserListSheet('following', 'Following'),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.24,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(106, 172, 67, 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        FutureBuilder(
                                          future: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').get(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 13, color: Color.fromRGBO(106, 172, 67, 1)));
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('Following', style: TextStyle(fontFamily: 'Mulish', fontSize: 11, color: Color.fromRGBO(106, 172, 67, 1))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Flairs (badges) flush to right edge
            if (_flairs.isNotEmpty)
              Positioned(
                right: 0,
                top: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < _flairs.length; i++) ...[
                      _FlagBadge(
                        text: _flairs[i]['label'] ?? 'Flair',
                        color: _parseFlairColor(_flairs[i]['color']) ?? Colors.deepPurpleAccent,
                        height: 24,
                      ),
                      if (i != _flairs.length - 1) SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            // WellWiz logo at bottom right
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
        color: color,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: ColorPalette.black,
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
