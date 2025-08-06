import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _updateDisplayName() async {
    final uid = user?.uid;
    if (uid != null && _displayNameController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'displayName': _displayNameController.text.trim()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตชื่อผู้ใช้เรียบร้อยแล้ว')),
      );
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร')),
      );
      return;
    }

    try {
      await user?.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(backgroundColor: const Color(0xFF00D09E),title: const Text('บัญชีของฉัน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('เปลี่ยนชื่อผู้ใช้', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'ชื่อใหม่'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _updateDisplayName,
                child: const Text('อัปเดตชื่อผู้ใช้'),
              ),
              const Divider(height: 40),
              const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _updatePassword,
                child: const Text('เปลี่ยนรหัสผ่าน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
