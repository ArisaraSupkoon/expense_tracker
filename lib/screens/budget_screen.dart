import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/widgets/arc_progress_bar.dart';
import 'dart:async';


class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, double> budgets = {}; // งบแต่ละหมวด
  Map<String, double> spentAmounts = {}; // ยอดใช้จริงแต่ละหมวด
  bool isLoading = true;
  late StreamSubscription<QuerySnapshot> _subscription;


  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.fastfood,
      'category': 'อาหาร/เครื่องดื่ม',
      'color': Colors.orange,
    },
    {'icon': Icons.directions_bus, 'category': 'เดินทาง', 'color': Colors.blue},
    {'icon': Icons.tv, 'category': 'บันเทิง', 'color': Colors.purple},
    {
      'icon': Icons.shopping_cart,
      'category': 'ช้อปปิ้ง',
      'color': Colors.green,
    },
    {
      'icon': Icons.lightbulb_outline,
      'category': 'สาธารณูปโภค',
      'color': Colors.redAccent,
    },
    {
      'icon': Icons.health_and_safety,
      'category': 'สุขภาพ/ความงาม',
      'color': Colors.pink,
    },
    {'icon': Icons.payments, 'category': 'ชำระหนี้', 'color': Colors.indigo},
    {'icon': Icons.category, 'category': 'อื่นๆ', 'color': Colors.grey},
  ];


  @override
  void initState() {
    super.initState();
    _loadBudgetsAndSpent();
  }

  Future<void> _loadBudgetsAndSpent() async {
    setState(() {
      isLoading = false; // กําหนดให้ isLoading เป็น true เมื่อเริ่มโหลด
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // โหลดงบประมาณจาก Firestore (collection 'budgets', doc uid)
    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(uid)
        .get();
    if (budgetDoc.exists) {
      final data = budgetDoc.data()!;
      // สมมติ data เป็น Map<String, dynamic> ที่เก็บงบแต่ละหมวดเป็น double
      budgets = data.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    // กำหนดช่วงเวลาของเดือนปัจจุบัน
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

     // Listen realtime records
  _subscription = FirebaseFirestore.instance
      .collection('records')
      .where('userID', isEqualTo: uid)
      .where('type', isEqualTo: 'expense')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
      .snapshots()
      .listen((snapshot) {
    spentAmounts.clear();
    for (var cat in categories) {
      spentAmounts[cat['category']] = 0.0;
    }
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'อื่นๆ';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      if (spentAmounts.containsKey(category)) {
        spentAmounts[category] = (spentAmounts[category] ?? 0) + amount;
      } else {
        spentAmounts[category] = amount;
      }
    }
    setState(() {
      isLoading = false;
    });
  });
}

@override
void dispose() {
  _subscription.cancel();
  super.dispose();
}

  Future<void> _showSetBudgetDialog(String category) async {
    final TextEditingController controller = TextEditingController(
      text: budgets[category]?.toStringAsFixed(0) ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ตั้งงบสำหรับ "$category"'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'งบประมาณ (บาท)',
            prefixText: '฿',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกจำนวนเงิน')),
                );
                return;
              }

              final value = double.tryParse(input);
              if (value == null || value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              budgets[category] = value;

              // อัปเดต Firestore
              await FirebaseFirestore.instance
                  .collection('budgets')
                  .doc(user.uid)
                  .set({category: value}, SetOptions(merge: true));

              Navigator.pop(context);

              setState(() {});
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  double get totalBudget => budgets.values.fold(0, (sum, val) => sum + val);
  double get totalSpent => spentAmounts.values.fold(0, (sum, val) => sum + val);

  @override
  Widget build(BuildContext context) {
    final double progress = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('งบประมาณรายจ่าย')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('งบประมาณรายจ่าย'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ArcProgressBar(
              progress: progress,
              size: 180,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.teal,
              strokeWidth: 14,
            ),
            const SizedBox(height: 20),
            Text(
              'ใช้ไปแล้ว: ฿${totalSpent.toStringAsFixed(0)} / ฿${totalBudget.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: categories.map((cat) {
                  final categoryName = cat['category'] as String;
                  final spent = spentAmounts[categoryName] ?? 0.0;
                  final budget = budgets[categoryName] ?? 0.0;
                  final color = cat['color'] as Color;
                  final icon = cat['icon'] as IconData;

                  final isBudgetSet = budget > 0;
                  final progress = isBudgetSet
                      ? (spent / budget).clamp(0.0, 1.0)
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withAlpha(
                              (0.15 * 255).toInt(),
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isBudgetSet) ...[
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '฿${spent.toStringAsFixed(0)} / ฿${budget.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ] else ...[
                                  GestureDetector(
                                    onTap: () =>
                                        _showSetBudgetDialog(categoryName),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: color,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ตั้งงบ',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            
          ],
        ),
      ),
    );
  }
}
