import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  bool isExpense = true;
  late AnimationController _animationController;

  List<String> expenseCategories = ['Gift'];
  List<String> incomeCategories = ['Pocket Money'];

  TextEditingController nameController = TextEditingController();
  int? editingIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true); // Reverses for up-down loop
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void showPopup(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void openDialog({bool isEdit = false, int? index}) {
    if (isEdit && index != null) {
      nameController.text = isExpense
          ? expenseCategories[index]
          : incomeCategories[index];
      editingIndex = index;
    } else {
      nameController.clear();
      editingIndex = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit
                    ? "Edit ${isExpense ? 'Expense' : 'Income'}"
                    : "Add ${isExpense ? 'Expense' : 'Income'}",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.red[400] : Colors.green[700],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isExpense ? Colors.red[100] : Colors.green[100],
                  hintText: "Name...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;

                  setState(() {
                    if (isEdit && editingIndex != null) {
                      if (isExpense) {
                        expenseCategories[editingIndex!] = nameController.text;
                      } else {
                        incomeCategories[editingIndex!] = nameController.text;
                      }
                      showPopup("Updated successfully", Colors.orange);
                    } else {
                      if (isExpense) {
                        expenseCategories.add(nameController.text);
                      } else {
                        incomeCategories.add(nameController.text);
                      }
                      showPopup("Added successfully", Colors.green);
                    }
                  });

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isExpense ? Colors.red[300] : Colors.green[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEdit ? "Update" : "Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  void deleteCategory(int index) {
    setState(() {
      if (isExpense) {
        expenseCategories.removeAt(index);
      } else {
        incomeCategories.removeAt(index);
      }
    });
    showPopup("Deleted successfully", Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExpense ? Colors.red[50]! : Colors.green[50]!;
    final headerColor = isExpense ? Colors.red[100]! : Colors.green[100]!;
    final iconColor = isExpense ? Colors.red : Colors.green;
    final textColor = isExpense ? Colors.red[800]! : Colors.green[800]!;
    final categories = isExpense ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: BubblePainter(
                  animationValue: _animationController.value,
                  isExpense: isExpense,
                ),
                child: Container(),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                // Standard Header (no curve)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  color: headerColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isExpense ? "Expense" : "Income",
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Row(
                        children: [
                          Switch(
                            value: isExpense,
                            onChanged: (value) =>
                                setState(() => isExpense = value),
                            activeColor: Colors.red,
                            inactiveTrackColor: Colors.green[200],
                            inactiveThumbColor: Colors.green[600],
                          ),
                          IconButton(
                            onPressed: () => openDialog(),
                            icon: const Icon(Icons.add_circle),
                            color: iconColor,
                            iconSize: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Category Cards
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: iconColor.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            isExpense ? Icons.upload : Icons.download,
                            color: iconColor,
                            size: 28,
                          ),
                          title: Text(
                            categories[index],
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    openDialog(isEdit: true, index: index),
                                icon: const Icon(Icons.edit),
                                color: Colors.orange,
                              ),
                              IconButton(
                                onPressed: () => deleteCategory(index),
                                icon: const Icon(Icons.delete),
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Up-and-down animation with sine wave motion
class BubblePainter extends CustomPainter {
  final double animationValue;
  final bool isExpense;
  BubblePainter({required this.animationValue, required this.isExpense});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isExpense ? Colors.redAccent : Colors.greenAccent)
          .withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final radius = 30.0 + (i * 3);
      final dx = size.width * (i / 10);
      final dy = size.height / 2 +
          sin((animationValue * 2 * pi) + i) * 100; // up-down wave motion
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}
