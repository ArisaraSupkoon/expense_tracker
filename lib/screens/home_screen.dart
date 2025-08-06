import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/widgets/arc_progress_bar.dart';
import 'package:expense_tracker/screens/budget_screen.dart';
import 'package:expense_tracker/screens/record_page.dart';
import 'package:expense_tracker/screens/visualization_screen.dart';
import 'package:expense_tracker/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool isLoading = true;

  String? username;
  bool isLoadingUsername = true;

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double budget = 0.0;
  List<Map<String, dynamic>> transactions = [];

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'th_TH',
    symbol: '฿',
  );

  @override
  void initState() {
    super.initState();

    username = 'ทดสอบ'; 
    isLoadingUsername = false;
    isLoading = false;
    /*
    _loadUsername();
    _loadDataRealtime();
    */
  }

  Future<void> _loadUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: $user'); // Debug log

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('Username data: ${userDoc.data()}'); // Debug log

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            username = userDoc.data()?['username'] ?? 'ไม่มีชื่อผู้ใช้';
            isLoadingUsername = false;
          });
        } else {
          setState(() {
            username = 'ไม่พบข้อมูลผู้ใช้';
            isLoadingUsername = false;
          });
        }
      } else {
        setState(() {
          username = 'กรุณาเข้าสู่ระบบ';
          isLoadingUsername = false;
        });
      }
    } catch (e) {
      print('Error loading username: $e');
      setState(() {
        username = 'เกิดข้อผิดพลาด';
        isLoadingUsername = false;
      });
    }
  }

  void _loadDataRealtime() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    print('🟢 User UID: ${user.uid}'); // ✅ ดูว่าเจอ user หรือไม่

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    FirebaseFirestore.instance
        .collection('budgets')
        .doc(user.uid)
        .snapshots()
        .listen((budgetDoc) {
          print(
            '📦 Budget snapshot: ${budgetDoc.data()}',
          ); // ✅ ดูงบว่ามีข้อมูลไหม

          double newBudget = 0.0;
          if (budgetDoc.exists) {
            final data = budgetDoc.data();
            if (data != null && data.containsKey('amount')) {
              newBudget = (data['amount'] as num).toDouble();
            }
          }
          setState(() {
            budget = newBudget;
          });
        });

    FirebaseFirestore.instance
        .collection('records')
        .where('userID', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          print(
            '📄 Records snapshot count: ${snapshot.docs.length}',
          ); // ✅ จำนวน record ที่โหลดได้

          double incomeSum = 0;
          double expenseSum = 0;
          List<Map<String, dynamic>> trans = [];

          for (var doc in snapshot.docs) {
            var data = doc.data();
            final amount = (data['amount'] as num).toDouble();
            final type = data['type'] as String;
            final category = data['category'] ?? '';
            final dateTimestamp = data['date'] as Timestamp;
            final date = dateTimestamp.toDate();

            print('🔍 Record: $data'); // ✅ แสดงข้อมูลแต่ละรายการ

            if (type == 'income') {
              incomeSum += amount;
            } else if (type == 'expense') {
              expenseSum += amount;
            }

            trans.add({
              'category': category,
              'amount': amount,
              'type': type,
              'date': date,
            });
          }

          setState(() {
            totalIncome = incomeSum;
            totalExpense = expenseSum;
            transactions = trans;
            isLoading = false;
          });
        });
  }

  Widget _buildHomePage() {
    double progress = budget > 0
        ? (totalExpense / budget).clamp(0.0, 1.0)
        : 0.0;
    double remaining = totalIncome - totalExpense;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
          color: const Color(0xFF00D09E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoadingUsername
                    ? 'กำลังโหลดชื่อผู้ใช้...'
                    : 'สวัสดี, $username',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAmountColumn('รายรับ', totalIncome, Colors.green),
                  _buildAmountColumn('รายจ่าย', totalExpense, Colors.red),
                  _buildAmountColumn('คงเหลือ', remaining, Colors.blue),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              color: const Color(0xFFF1FFF3),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF7E2),
                          border: Border.all(
                            color: const Color(0xFF00D09E),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'งบประมาณรายจ่าย',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ArcProgressBar(
                                    progress: progress,
                                    size: 120,
                                    backgroundColor: Colors.grey.shade300,
                                    progressColor: progress > 0.8
                                        ? Colors.red
                                        : const Color(0xFF00D09E),
                                    strokeWidth: 16,
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ใช้ไปแล้ว',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${currencyFormat.format(totalExpense)} / ${currencyFormat.format(budget)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const BudgetScreen(),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: const [
                                            Text(
                                              'ดูรายละเอียด',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF00D09E),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Color(0xFF00D09E),
                                            ),
                                          ],
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
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 32),
                    const Text(
                      'รายการล่าสุด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: transactions.map((tx) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (0.05 * 255).toInt(),
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['category'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                      'th_TH',
                                    ).format(tx['date']),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              Text(
                                '${tx['type'] == 'expense' ? '-' : '+'}${currencyFormat.format(tx['amount'])}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: tx['type'] == 'expense'
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountColumn(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha((0.8 * 255).toInt()),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEntryPage() {
    return const RecordPage();
  }

  Widget _buildVisualizationPage() {
    return const VisualizationScreen();
  }

  Widget _buildSettingsPage() {
    return const SettingsScreen();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getPages() {
    return [
      _buildHomePage(),
      _buildAddEntryPage(),
      _buildVisualizationPage(),
      _buildSettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Debug log เพื่อตรวจสอบสถานะ loading
    print('isLoading: $isLoading, isLoadingUsername: $isLoadingUsername');

    if (isLoading || isLoadingUsername) {
      return const Scaffold(
        body: Center(child: Text('กำลังโหลดข้อมูลหรือไม่มีข้อมูลผู้ใช้')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      body: _getPages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00D09E),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'บันทึก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'สรุป',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
