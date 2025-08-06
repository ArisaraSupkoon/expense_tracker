import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notificationsEnabled = false;
  bool _biometricLogin = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? false;
      _biometricLogin = prefs.getBool('biometric') ?? false;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', value);
    setState(() {
      _biometricLogin = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(backgroundColor: const Color(0xFF00D09E),title: const Text('ตั้งค่า')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('เปิดการแจ้งเตือน'),
            value: _notificationsEnabled,
            onChanged: _toggleNotification,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('เข้าสู่ระบบด้วย Biometric'),
            value: _biometricLogin,
            onChanged: _toggleBiometric,
          ),
        ],
      ),
    );
  }
}
