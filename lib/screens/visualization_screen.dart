//import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  String _selectedPeriod = 'รายวัน'; // รายวัน รายสัปดาห์ รายเดือน รายปี
  String _selectedType = 'expense'; // 'expense' หรือ 'income'

  DateTime get _now => DateTime.now();

  Map<String, DateTimeRange> getPeriodRange() {
    late DateTime start;
    late DateTime end;

    if (_selectedPeriod == 'รายวัน') {
      start = DateTime(_now.year, _now.month, _now.day);
      end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
    } else if (_selectedPeriod == 'รายสัปดาห์') {
      int weekday = _now.weekday;
      start = _now.subtract(Duration(days: weekday - 1));
      end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));
    } else if (_selectedPeriod == 'รายเดือน') {
      start = DateTime(_now.year, _now.month, 1);
      end = DateTime(
        _now.year,
        _now.month + 1,
        1,
      ).subtract(const Duration(seconds: 1));
    } else {
      start = DateTime(_now.year, 1, 1);
      end = DateTime(_now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
    }

    return {'range': DateTimeRange(start: start, end: end)};
  }

  @override
  Widget build(BuildContext context) {
    
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบก่อนใช้งาน')),
      );
    }
    
    
    final range = getPeriodRange()['range']!;

    return Scaffold(
      appBar: AppBar(title: const Text('สรุปรายรับ-รายจ่าย')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ToggleButtons(
                isSelected: [
                  _selectedType == 'income',
                  _selectedType == 'expense',
                ], 
                onPressed: (index) {
                  setState(() {
                    _selectedType = index == 0
                        ? 'income'
                        : 'expense'; 
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('รายรับ'), 
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('รายจ่าย'), 
                  ),
                ],
              ),

              const SizedBox(height: 12),
              ToggleButtons(
                isSelected: [
                  _selectedPeriod == 'รายวัน',
                  _selectedPeriod == 'รายสัปดาห์',
                  _selectedPeriod == 'รายเดือน',
                  _selectedPeriod == 'รายปี',
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedPeriod = [
                      'รายวัน',
                      'รายสัปดาห์',
                      'รายเดือน',
                      'รายปี',
                    ][index];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('รายวัน'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('รายสัปดาห์'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('รายเดือน'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('รายปี'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('records')
                      .where('userID', isEqualTo: userId)
                      .where('type', isEqualTo: _selectedType)
                      .where(
                        'date',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
                      )
                      .where(
                        'date',
                        isLessThanOrEqualTo: Timestamp.fromDate(range.end),
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('ไม่มีข้อมูล'));
                    }

                    final docs = snapshot.data!.docs;

                    Map<String, double> categorySums = {};
                    double total = 0;

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      String category = data['category'] ?? 'อื่นๆ';
                      double amount = (data['amount'] as num).toDouble();

                      categorySums[category] =
                          (categorySums[category] ?? 0) + amount;
                      total += amount;
                    }

                    if (total == 0) {
                      return const Center(child: Text('ไม่มีข้อมูล'));
                    }

                    List<PieChartSectionData> pieSections = [];
                    int i = 0;
                    for (var entry in categorySums.entries) {
                      final percent = (entry.value / total) * 100;
                      final color =
                          Colors.primaries[i % Colors.primaries.length];

                      pieSections.add(
                        PieChartSectionData(
                          value: entry.value,
                          title: '${percent.toStringAsFixed(1)}%',
                          color: color,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                      i++;
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: pieSections,
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'รวมทั้งหมด: ${total.toStringAsFixed(2)} บาท',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            children: categorySums.entries.map((e) {
                              final percent = (e.value / total) * 100;
                              return ListTile(
                                title: Text(e.key),
                                trailing: Text(
                                  '${e.value.toStringAsFixed(2)} บาท (${percent.toStringAsFixed(1)}%)',
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
