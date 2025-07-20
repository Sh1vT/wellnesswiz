import 'package:flutter/material.dart';
import 'package:wellwiz/chat/content/alerts/widgets/emergency_service.dart';
import 'package:wellwiz/quick_access/content/account/widgets/account_info_card.dart';
import 'package:wellwiz/quick_access/content/account/widgets/quick_access_title.dart';
import 'package:wellwiz/quick_access/content/reminder_only/reminder_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/quick_access/content/account/widgets/gyro_reactive_card.dart';
import 'package:wellwiz/quick_access/content/account/edit_account_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wellwiz/utils/color_palette.dart';
import '../providers/user_info_provider.dart';
import 'package:shimmer/shimmer.dart';

class QuickAccessPage extends ConsumerStatefulWidget {
  const QuickAccessPage({super.key});

  @override
  ConsumerState<QuickAccessPage> createState() => _QuickAccessPageState();
}

class _QuickAccessPageState extends ConsumerState<QuickAccessPage> {

  Future<void> _fetchHandle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        // _isLoading = false; // Removed
      });
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      // _handle = doc.data()?['handle']; // Removed
      // _isLoading = false; // Removed
    });
  }

  Future<bool> _isHandleUnique(String handle) async {
    final query = await FirebaseFirestore.instance.collection('users').where('handle', isEqualTo: handle).get();
    return query.docs.isEmpty;
  }

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Always fetch the current name from Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final currentName = doc.data()?['name'] ?? '';
    final TextEditingController nameController = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Edit Name',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey.shade700,
            fontFamily: 'Mulish',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
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
    if (result != null && result.isNotEmpty && result != currentName) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'name': result}, SetOptions(merge: true));
      ref.read(userInfoProvider.notifier).loadUserInfo();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated!')));
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
                                    ? 'Are you sure you want to remove \\${userData['name']} (@\\${userData['handle']}) from your followers?'
                                    : 'Are you sure you want to unfollow \\${userData['name']} (@\\${userData['handle']})?',
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

  Future<void> _pickTimeAndScheduleDailyThought() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      helpText: "Choose time for daily positive thoughts!",
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromRGBO(106, 172, 67, 1),
            colorScheme: ColorScheme.light(primary: Color.fromRGBO(106, 172, 67, 1)),
          ),
          child: child!,
        );
      },
    );
    if (selectedTime != null) {
      final int hour = selectedTime.hour;
      final int minute = selectedTime.minute;
      print('[DEBUG] Picked time for positivity: $hour:$minute');
      // final ThoughtsService _thoughtsService = ThoughtsService(); // Removed
      // await _thoughtsService.scheduleDailyThoughtNotification(hour, minute); // Removed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Daily positive thought scheduled for ${selectedTime.format(context)}!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfoProvider);
    return ListView(
      children: [
        const QuickAccessTitle(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: GyroReactiveCard(
            child: userInfoAsync.when(
              loading: () => const AccountInfoCardShimmer(),
              error: (e, st) => const Center(child: Text('Error loading user info')),
              data: (userInfo) => AccountInfoCard(
                name: userInfo.name,
                handle: userInfo.handle,
                photoURL: userInfo.photoURL,
                age: userInfo.age,
                followers: userInfo.followersCount,
                following: userInfo.followingCount,
                flairs: userInfo.flairs,
                ref: ref,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _QuickAccessGridTile(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () async {
                      final notifier = ref.read(userInfoProvider.notifier);
                      final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (context) => const EditAccountInfoSheet(),
                  );
                      if (result == true) {
                        notifier.loadUserInfo(); // Refresh provider after editing
                      }
                },
              ),
              _QuickAccessGridTile(
                icon: Icons.alarm,
                label: 'Remind',
                onTap: () {
                  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ReminderPage(userId: userId);
                  }));
                },
              ),
              _QuickAccessGridTile(
                icon: Icons.health_and_safety_outlined,
                label: 'Positivity',
                onTap: _pickTimeAndScheduleDailyThought,
              ),
              _QuickAccessGridTile(
                icon: Icons.notifications_active_outlined,
                label: 'SOS',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return EmergencyScreen();
                  }));
                },
              ),
              _QuickAccessGridTile(
                icon: Icons.logout,
                label: 'Logout',
                iconColor: Colors.red.shade700,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  // Removed manual navigation to LoginScreen. Let main.dart handle navigation.
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _QuickAccessGridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _QuickAccessGridTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Lighter gray background
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? Color(0xFF6AAC43),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: iconColor ?? Colors.grey.shade700,
                ),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this widget at the end of the file for the scale animation on tap
class _AnimatedScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedScaleOnTap({required this.child, required this.onTap});

  @override
  State<_AnimatedScaleOnTap> createState() => _AnimatedScaleOnTapState();
}

class _AnimatedScaleOnTapState extends State<_AnimatedScaleOnTap> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _controller.addListener(() {
      setState(() {
        _scale = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

// Shimmer skeleton for AccountInfoCard
class AccountInfoCardShimmer extends StatelessWidget {
  const AccountInfoCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          Container(
                            height: 16,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
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
          ),
        ),
      ),
    );
  }
}
