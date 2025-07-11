import 'package:casharoo_app/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // Firestore
  final FirestoreService firestoreService = FirestoreService();

  bool isExpense = true;
  String? selectedCategory;

  // Controller
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  // Get current category type
  String get currentType => isExpense ? 'Expense' : 'Income';

  @override
  void initState() {
    super.initState();
    // Removed automatic default category initialization
    // Users will start with empty categories and can add their own
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExpense ? Colors.red[50]! : Colors.green[50]!;
    final headerColor = isExpense ? Colors.red[100]! : Colors.green[100]!;
    final iconColor = isExpense ? Colors.red : Colors.green;
    final textColor = isExpense ? Colors.red[800]! : Colors.green[800]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        title: Text(
          isExpense ? "Add Expense" : "Add Income",
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Switch(
                      value: isExpense,
                      onChanged: (bool value) {
                        setState(() {
                          isExpense = value;
                          selectedCategory =
                              null; // Reset category when switching
                        });
                      },
                      inactiveTrackColor: Colors.green[200],
                      inactiveThumbColor: Colors.green,
                      activeColor: Colors.red,
                    ),
                    Text(
                      isExpense ? 'Expense' : 'Income',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    labelStyle: GoogleFonts.montserrat(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Category',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getCategories(currentType),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading categories');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      List<String> categories = [];
                      if (snapshot.hasData) {
                        categories =
                            snapshot.data!.docs
                                .map(
                                  (doc) => doc.data() as Map<String, dynamic>,
                                )
                                .map((data) => data['name'] as String)
                                .toList();
                      }

                      // Reset selected category if it's not in the current list
                      if (selectedCategory != null &&
                          !categories.contains(selectedCategory)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            selectedCategory = null;
                          });
                        });
                      }

                      return DropdownButton<String>(
                        value: selectedCategory,
                        hint: Text(
                          'Select Category',
                          style: GoogleFonts.montserrat(),
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items:
                            categories.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.montserrat(),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Enter Date",
                    labelStyle: GoogleFonts.montserrat(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2099),
                    );

                    if (pickedDate != null) {
                      String formattedDate = DateFormat(
                        'dd/MM/yyyy',
                      ).format(pickedDate);

                      dateController.text = formattedDate;
                    }
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isNotEmpty &&
                          selectedCategory != null &&
                          dateController.text.isNotEmpty) {
                        try {
                          int amount = int.parse(amountController.text);
                          String type = isExpense ? "Expense" : "Income";

                          await firestoreService.addTransaction(
                            amount,
                            selectedCategory!,
                            dateController.text,
                            type,
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving transaction: $e'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill all fields')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.montserrat(fontSize: 16),
                    ),
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
