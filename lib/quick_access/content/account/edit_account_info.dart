import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/utils/color_palette.dart';

class EditAccountInfoSheet extends StatefulWidget {
  const EditAccountInfoSheet({Key? key}) : super(key: key);

  @override
  State<EditAccountInfoSheet> createState() => _EditAccountInfoSheetState();
}

class _EditAccountInfoSheetState extends State<EditAccountInfoSheet> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _nameController = TextEditingController();
  String? gender;
  List<String> selectedGoals = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final List<String> allGoals = const [
    'Better Sleep',
    'Stress Reduction',
    'Fitness',
    'Medication Adherence',
    'Healthy Eating',
    'Mental Peace',
    'Weight Loss',
    'Quit Smoking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    setState(() {
      _displayNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _ageController.text = (data['age']?.toString() ?? '');
      _nameController.text = (data['name'] ?? '');
      gender = data['gender'] ?? '';
      selectedGoals = List<String>.from(data['goals'] ?? []);
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(_displayNameController.text.trim());
      await user.updateEmail(_emailController.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': gender,
        'goals': selectedGoals,
        'name': _nameController.text.trim(),
      }, SetOptions(merge: true));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to update info: $e'; });
    } finally {
      setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit, color: Color(0xFF6AAC43)),
                          const SizedBox(width: 10),
                          const Text('Edit Account Info', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'Display Name'),
                        style: const TextStyle(fontFamily: 'Mulish'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        style: const TextStyle(fontFamily: 'Mulish'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        style: const TextStyle(fontFamily: 'Mulish'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        style: const TextStyle(fontFamily: 'Mulish'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Gender', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _GenderIconButton(
                            icon: Icons.male_rounded,
                            selected: gender == 'Male',
                            onTap: () => setState(() => gender = 'Male'),
                          ),
                          const SizedBox(width: 8),
                          _GenderIconButton(
                            icon: Icons.female_rounded,
                            selected: gender == 'Female',
                            onTap: () => setState(() => gender = 'Female'),
                          ),
                          const SizedBox(width: 8),
                          _GenderIconButton(
                            icon: Icons.transgender_rounded,
                            selected: gender == 'Transgender',
                            onTap: () => setState(() => gender = 'Transgender'),
                          ),
                          const SizedBox(width: 8),
                          _GenderIconButton(
                            icon: Icons.question_mark_rounded,
                            selected: gender == 'Rather not say',
                            onTap: () => setState(() => gender = 'Rather not say'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Goals', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mulish', fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: allGoals.map((goal) {
                          final selected = selectedGoals.contains(goal);
                          return ChoiceChip(
                            label: Text(goal, style: const TextStyle(fontFamily: 'Mulish')),
                            selected: selected,
                            selectedColor: ColorPalette.green,
                            backgroundColor: Colors.grey[200],
                            onSelected: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedGoals.add(goal);
                                } else {
                                  selectedGoals.remove(goal);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GenderIconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? ColorPalette.green : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ColorPalette.green : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey.shade700),
        ),
      ),
    );
  }
} 