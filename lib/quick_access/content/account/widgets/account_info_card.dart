import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountInfoCard extends StatefulWidget {
  const AccountInfoCard({Key? key}) : super(key: key);

  @override
  State<AccountInfoCard> createState() => _AccountInfoCardState();
}

class _AccountInfoCardState extends State<AccountInfoCard> {
  String? _handle;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHandle();
  }

  Future<void> _fetchHandle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _handle = doc.data()?['handle'];
      _isLoading = false;
    });
  }

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final TextEditingController nameController = TextEditingController(text: user.displayName ?? '');
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontFamily: 'Mulish')),
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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'displayName': result}, SetOptions(merge: true));
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Display name updated!')));
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
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
                child: Text(title, style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              if (users.isEmpty)
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
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, i) {
                      final userData = users[i];
                      return ListTile(
                        leading: userData['photoURL'].isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(userData['photoURL']))
                            : const CircleAvatar(child: Icon(Icons.account_circle)),
                        title: Text(userData['displayName'], style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold)),
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
                                    ? "Are you sure you want to remove \${userData['displayName']} (@\${userData['handle']}) from your followers?"
                                    : "Are you sure you want to unfollow \${userData['displayName']} (@\${userData['handle']})?",
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (_isLoading) {
      // Shimmer placeholder
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 120,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 80,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 100,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          height: 28,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          height: 28,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (user == null) {
      return const Center(child: Text('No user signed in.'));
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    radius: 38,
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.account_circle, size: 60, color: Colors.grey)
                        : null,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName ?? 'No display name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(106, 172, 67, 1),
                                fontFamily: 'Mulish',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.grey.shade700, size: 22),
                            tooltip: 'Edit display name',
                            onPressed: _editDisplayName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_handle != null)
                        Text(
                          '@$_handle',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 106, 172, 67),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? 'No email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Mulish',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showUserListSheet('followers', 'Followers'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 15, color: Color.fromRGBO(106, 172, 67, 1)));
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text('Followers', style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: Color.fromRGBO(106, 172, 67, 1))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showUserListSheet('following', 'Following'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 15, color: Color.fromRGBO(106, 172, 67, 1)));
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text('Following', style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: Color.fromRGBO(106, 172, 67, 1))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 