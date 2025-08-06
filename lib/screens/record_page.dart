import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool isIncome = false; // ใช้แทน type = 'income' หรือ 'expense'
  String? selectedCategory;
  double? amount;
  String note = '';
  DateTime selectedDate = DateTime.now();

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final incomeCategories = ['รายได้ประจำ', 'รายได้เสริม'];
  final expenseCategories = [
    'อาหาร/เครื่องดื่ม',
    'ช้อปปิ้ง',
    'เดินทาง',
    'บันเทิง',
    'สาธารณูปโภค',
    'สุขภาพ/ความงาม',
    'ชำระหนี้',
    'อื่นๆ',
  ];

  late stt.SpeechToText _speech;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => isListening = true);
      _speech.listen(
        onResult: (val) {
          final text = val.recognizedWords;
          parseSpeech(text);
        },
        localeId: 'th_TH',
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => isListening = false);
  }

  void parseSpeech(String text) {
    final regex = RegExp(r'(.+?)\s?(\d+(?:\.\d+)?)\s?(บาท)?');
    final match = regex.firstMatch(text);

    if (match != null) {
      final extractedNote = match.group(1)?.trim() ?? '';
      final numberText = match.group(2) ?? '';
      double? extractedAmount = double.tryParse(numberText);

      // ถ้าแปลงตัวเลขไม่ได้ ลองแปลงคำพูดไทยเป็นตัวเลข
      if (extractedAmount == null) {
        final thaiNumber = convertThaiTextToNumber(numberText);
        if (thaiNumber != null) {
          extractedAmount = thaiNumber.toDouble();
        }
      }

      setState(() {
        note = extractedNote;
        amount = extractedAmount;
        noteController.text = extractedNote;
        amountController.text = extractedAmount?.toString() ?? '';
      });
    } else {
      // fallback
      setState(() {
        note = text;
        noteController.text = text;
      });
    }
  }

  void saveToFirestore() async {
    if (selectedCategory == null || amount == null) return;

    await FirebaseFirestore.instance.collection('records').add({
      'type': isIncome ? 'income' : 'expense',
      'category': selectedCategory,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(selectedDate),
      'createdAt': Timestamp.now(),
      'userID': FirebaseAuth.instance.currentUser!.uid,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกเรียบร้อย!')));

    setState(() {
      selectedCategory = null;
      amountController.clear();
      noteController.clear();
      amount = null;
      note = '';
      selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = isIncome ? incomeCategories : expenseCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        //leading: BackButton(color: Colors.black),
        backgroundColor: const Color(0xFF00D09E),
        elevation: 0,
        title: const Text(
          'บันทึกข้อมูล',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ToggleButtons(
                isSelected: [isIncome, !isIncome],
                onPressed: (index) {
                  setState(() {
                    isIncome = index == 0;
                    selectedCategory = null;
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
            ),

            const SizedBox(height: 16),

            // Dropdown หมวดหมู่
            const Text(
              'เลือกหมวดหมู่',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                hintText: 'เลือกหมวดหมู่',
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategory = val!;
                });
              },
            ),

            const SizedBox(height: 20),

            // Note
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'โน้ต / คำอธิบาย',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (val) => note = val,
            ),

            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'จำนวนเงิน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  amount = double.tryParse(val);
                });
              },
            ),

            const SizedBox(height: 16),

            // วันที่
            Row(
              children: [
                const Text('วันที่: '),
                Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),

            const Spacer(),

            // ปุ่มไมโครโฟน
            Center(
              child: GestureDetector(
                onTap: isListening ? stopListening : startListening,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isListening ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่มบันทึก
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'บันทึก',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

int? convertThaiTextToNumber(String input) {
  final numberWords = {
    'ศูนย์': 0,
    'หนึ่ง': 1,
    'สอง': 2,
    'สาม': 3,
    'สี่': 4,
    'ห้า': 5,
    'หก': 6,
    'เจ็ด': 7,
    'แปด': 8,
    'เก้า': 9,
    'สิบ': 10,
    'ร้อย': 100,
    'พัน': 1000,
    'หมื่น': 10000,
    'แสน': 100000,
    'ล้าน': 1000000,
  };

  int result = 0;
  int temp = 0;
  int lastUnit = 0;

  final tokens = RegExp(
    r'[ก-๙]+',
  ).allMatches(input).map((e) => e.group(0)!).toList();

  for (final word in tokens) {
    if (numberWords.containsKey(word)) {
      final value = numberWords[word]!;
      if (value >= 10) {
        if (temp == 0) temp = 1;
        temp *= value;
        lastUnit = value;
      } else {
        temp += value;
      }
    } else {
      if (temp != 0) {
        result += temp;
        temp = 0;
      }
    }
  }

  result += temp;
  return result > 0 ? result : null;
}
