import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/utils/color_palette.dart';

class UserSearchSection extends StatefulWidget {
  const UserSearchSection({super.key});

  @override
  State<UserSearchSection> createState() => _UserSearchSectionState();
}

class _UserSearchSectionState extends State<UserSearchSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Parent ListView handles scrolling
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by handle or name',
              hintStyle: const TextStyle(fontFamily: 'Mulish', color: ColorPalette.black),
              prefixIcon: const Icon(Icons.search, color: ColorPalette.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchTerm = val.trim()),
          ),
        ),
        SizedBox(
          height: 400, // Adjust as needed for your UI
          child: _searchTerm.isEmpty
              ? Center(child: Text('Type to search users', style: TextStyle(fontFamily: 'Mulish')))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('handle', isGreaterThanOrEqualTo: _searchTerm)
                      .where('handle', isLessThanOrEqualTo: _searchTerm + '\uf8ff')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final handle = (data['handle'] ?? '').toString().toLowerCase();
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      final term = _searchTerm.toLowerCase();
                      return handle.contains(term) || name.contains(term);
                    }).where((doc) => doc.id != currentUser?.uid).toList();
                    if (docs.isEmpty) {
                      return Center(child: Text('No users found', style: TextStyle(fontFamily: 'Mulish')));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final userId = docs[i].id;
                        return _UserListTile(
                          userId: userId,
                          displayName: data['displayName'] ?? '',
                          handle: data['handle'] ?? '',
                          photoUrl: data['photoURL'] ?? '',
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UserListTile extends StatefulWidget {
  final String userId;
  final String displayName;
  final String handle;
  final String photoUrl;
  const _UserListTile({required this.userId, required this.displayName, required this.handle, required this.photoUrl});

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  bool _isFollowing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(widget.userId)
        .get();
    setState(() {
      _isFollowing = doc.exists;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(widget.userId);
    final followersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUser.uid);
    setState(() => _loading = true);
    if (_isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
    } else {
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followersRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
    setState(() {
      _isFollowing = !_isFollowing;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.photoUrl.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(widget.photoUrl))
          : const CircleAvatar(child: Icon(Icons.account_circle)),
      title: Text(widget.displayName, style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
      subtitle: Text('@${widget.handle}', style: TextStyle(fontFamily: 'Mulish', color: Colors.grey.shade700)),
      trailing: _loading
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey.shade300 : Color.fromARGB(255, 106, 172, 67),
                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
            ),
    );
  }
} 