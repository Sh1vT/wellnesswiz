import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _handleController = TextEditingController();
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

  Future<bool> _isHandleUnique(String handle) async {
    final query = await FirebaseFirestore.instance.collection('users').where('handle', isEqualTo: handle).get();
    return query.docs.isEmpty;
  }

  Future<void> _setHandle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final handle = _handleController.text.trim();
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!valid.hasMatch(handle)) {
      setState(() {
        _error = 'Handle must be 3-20 characters, letters, numbers, or underscores.';
      });
      return;
    }
    if (!await _isHandleUnique(handle)) {
      setState(() {
        _error = 'Handle already taken.';
      });
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'handle': handle}, SetOptions(merge: true));
    setState(() {
      _handle = handle;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handle set!')));
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
      // Optionally update in Firestore as well
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'displayName': result}, SetOptions(merge: true));
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Display name updated!')));
    }
  }

  Future<List<Map<String, dynamic>>> _getUserList(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
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
    return users;
  }

  void _showUserListSheet(String type, String title) async {
    final users = await _getUserList(type);
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
                                    ? 'Are you sure you want to remove ${userData['displayName']} (@${userData['handle']}) from your followers?'
                                    : 'Are you sure you want to unfollow ${userData['displayName']} (@${userData['handle']})?',
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
                                // Remove follower: delete their doc from your followers, and your UID from their following
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
                                // Unfollow: delete their doc from your following, and your UID from their followers
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
                              Navigator.of(context).pop(); // Close the sheet after removal
                              setState(() {}); // Refresh the UI
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

  Widget _buildTitle() {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            "My ",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                fontSize: 40,
                color: Color.fromARGB(255, 106, 172, 67)),
          ),
          Text(
            "Account",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                fontSize: 40,
                color: Color.fromRGBO(97, 97, 97, 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor, Color? textColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Center(
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? Colors.grey.shade700,
                ),
                const SizedBox(width: 20),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.grey.shade700,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.navigate_next_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        children: [
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (user == null)
            const Center(child: Text('No user signed in.'))
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.grey.withOpacity(0.08),
                  //     blurRadius: 12,
                  //     offset: const Offset(0, 4),
                  //   ),
                  // ],
                  color: Colors.grey.shade200,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and profile info (left 50%)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (user.photoURL != null)
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(user.photoURL!),
                              )
                            else
                              const CircleAvatar(
                                radius: 40,
                                child: Icon(Icons.account_circle, size: 60),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              user.displayName ?? 'No display name',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (_handle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Text(
                                  '@$_handle',
                                  style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 106, 172, 67), fontWeight: FontWeight.w600),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'No email',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Stats (right 50%)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showUserListSheet('followers', 'Followers'),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 106, 172, 67),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        FutureBuilder(
                                          future: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('followers').get(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 18, color: Colors.white));
                                          },
                                        ),
                                        const Text('Followers', style: TextStyle(fontFamily: 'Mulish', fontSize: 15, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showUserListSheet('following', 'Following'),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 106, 172, 67),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        FutureBuilder(
                                          future: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').get(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                            return Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 18, color: Colors.white));
                                          },
                                        ),
                                        const Text('Following', style: TextStyle(fontFamily: 'Mulish', fontSize: 15, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildCardButton(
              icon: Icons.edit,
              label: 'Edit Profile',
              iconColor: Colors.grey.shade700,
              textColor: Colors.grey.shade700,
              onTap: _editDisplayName,
            ),
            _buildCardButton(
              icon: Icons.logout,
              label: 'Sign Out',
              iconColor: Colors.red.shade400,
              textColor: Colors.red.shade400,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ],
      ),
    );
  }
} 