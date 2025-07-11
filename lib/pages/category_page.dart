import 'dart:math';
import 'package:casharoo_app/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirestoreService firestoreService = FirestoreService();

  TextEditingController nameController = TextEditingController();
  String? editingDocId;

  String get currentType => isExpense ? 'Expense' : 'Income';

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

  void openDialog({bool isEdit = false, String? docId, String? categoryName}) {
    if (isEdit && docId != null && categoryName != null) {
      nameController.text = categoryName;
      editingDocId = docId;
    } else {
      nameController.clear();
      editingDocId = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  try {
                    if (isEdit && editingDocId != null) {
                      await firestoreService.updateCategory(
                        editingDocId!,
                        nameController.text.trim(),
                      );
                      showPopup("Updated successfully", Colors.orange);
                    } else {
                      await firestoreService.addCategory(
                        nameController.text.trim(),
                        currentType,
                      );
                      showPopup("Added successfully", Colors.green);
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    showPopup("Error: $e", Colors.red);
                  }
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

  void deleteCategory(String docId) async {
    try {
      await firestoreService.deleteCategory(docId);
      showPopup("Deleted successfully", Colors.redAccent);
    } catch (e) {
      showPopup("Error deleting: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExpense ? Colors.red[50]! : Colors.green[50]!;
    final headerColor = isExpense ? Colors.red[100]! : Colors.green[100]!;
    final iconColor = isExpense ? Colors.red : Colors.green;
    final textColor = isExpense ? Colors.red[800]! : Colors.green[800]!;

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
          Column(
            children: [
              // Header with switch and add button
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                color: headerColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isExpense ? "Expense Categories" : "Income Categories",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Switch(
                          value: isExpense,
                          onChanged:
                              (value) => setState(() => isExpense = value),
                          activeColor: Colors.red,
                          inactiveTrackColor: Colors.green[200],
                          inactiveThumbColor: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => openDialog(),
                          icon: const Icon(Icons.add_circle),
                          color: iconColor,
                          iconSize: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Category Cards with StreamBuilder
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getCategories(currentType),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.montserrat(),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: iconColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${currentType.toLowerCase()} categories yet',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add one',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        // Sort documents by name on client side
                        List<DocumentSnapshot> sortedDocs =
                            snapshot.data!.docs.toList();
                        sortedDocs.sort((a, b) {
                          Map<String, dynamic> dataA =
                              a.data() as Map<String, dynamic>;
                          Map<String, dynamic> dataB =
                              b.data() as Map<String, dynamic>;
                          return dataA['name'].toString().compareTo(
                            dataB['name'].toString(),
                          );
                        });

                        DocumentSnapshot document = sortedDocs[index];
                        String docID = document.id;
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        String categoryName = data['name'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: iconColor.withOpacity(0.3),
                              width: 2,
                            ),
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
                              categoryName,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed:
                                      () => openDialog(
                                        isEdit: true,
                                        docId: docID,
                                        categoryName: categoryName,
                                      ),
                                  icon: const Icon(Icons.edit),
                                  color: Colors.orange,
                                ),
                                IconButton(
                                  onPressed: () => deleteCategory(docID),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
    final paint =
        Paint()
          ..color = (isExpense ? Colors.redAccent : Colors.greenAccent)
              .withOpacity(0.1)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final radius = 30.0 + (i * 3);
      final dx = size.width * (i / 10);
      final dy =
          size.height / 2 +
          sin((animationValue * 2 * pi) + i) * 100; // up-down wave motion
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}
