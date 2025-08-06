import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // บัญชีของฉัน
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('บัญชีของฉัน'),
            subtitle: const Text('เปลี่ยนชื่อผู้ใช้ / รหัสผ่าน'),
            onTap: () {
              Navigator.pushNamed(context, '/account');
            },
          ),

          const Divider(),

          // ตั้งค่า
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('ตั้งค่า'),
            subtitle: const Text('แจ้งเตือน / การเข้าสู่ระบบ'),
            onTap: () {
              Navigator.pushNamed(context, '/preferences');
            },
          ),

          const Divider(),

          // นโยบายความเป็นส่วนตัว
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('นโยบายความเป็นส่วนตัว'),
            onTap: () {
              Navigator.pushNamed(context, '/privacy');
            },
          ),

          const Divider(),

          // ติดต่อเรา
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('ติดต่อเรา'),
            onTap: () {
              Navigator.pushNamed(context, '/contact');
            },
          ),

          const Divider(),

          // ออกจากระบบ
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () => _signOut(context),
          ),

          const Divider(),
        ],
      ),
    );
  }
}
