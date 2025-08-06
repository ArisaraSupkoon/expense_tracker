import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
    /*
    // เพิ่ม delay สั้น ๆ เพื่อแสดง splash logo ก่อนเช็คสถานะ
    Timer(const Duration(seconds: 2), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ดึงชื่อจาก Firestore ก่อน
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final username = doc['username'] ?? 'ผู้ใช้';

        // ส่งชื่อไปยัง HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00D09E),
      body: Center(
        child: Stack(
          children: [
            Text(
              'Say&Save',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = Colors.black,
              ),
            ),
            const Text(
              'Say&Save',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 4),
                    blurRadius: 12,
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
