import 'package:casharoo_app/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final DateTime selectedDate;

  const HomePage({super.key, required this.selectedDate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double totalBalance = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
  }

  void _loadData() {
    _calculateTotalsForDate();
    _loadTransactionsForDate();
  }

  void _calculateTotalsForDate() {
    String formattedDate = DateFormat('dd/MM/yyyy').format(widget.selectedDate);
    firestoreService.getTransactionsByDate(formattedDate).listen((snapshot) {
      double income = 0.0;
      double expense = 0.0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String type = data['type'] ?? '';
        int amount = data['amount'] ?? 0;

        if (type == 'Income') {
          income += amount.toDouble();
        } else if (type == 'Expense') {
          expense += amount.toDouble();
        }
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
        totalBalance = income - expense;
      });
    });
  }

  void _loadTransactionsForDate() {
    String formattedDate = DateFormat('dd/MM/yyyy').format(widget.selectedDate);
    firestoreService.getTransactionsByDate(formattedDate).listen((snapshot) {
      List<Map<String, dynamic>> transactions = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        transactions.add(data);
      }

      // Sort transactions by timestamp (most recent first)
      transactions.sort((a, b) {
        Timestamp timestampA = a['timestamp'] ?? Timestamp.now();
        Timestamp timestampB = b['timestamp'] ?? Timestamp.now();
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        recentTransactions = transactions;
      });
    });
  }

  String _getDateSubtitle() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime selectedDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    if (selectedDay == today) {
      return "Today's financial overview";
    } else {
      return "${DateFormat('MMMM dd, yyyy').format(widget.selectedDate)} overview";
    }
  }

  IconData _getIconForCategory(String category, bool isIncome) {
    if (isIncome) {
      switch (category.toLowerCase()) {
        case 'salary':
          return Icons.account_balance_wallet_rounded;
        case 'freelance':
          return Icons.work_outline_rounded;
        case 'investment':
          return Icons.trending_up_rounded;
        case 'business':
          return Icons.business_rounded;
        case 'gift':
          return Icons.card_giftcard_rounded;
        default:
          return Icons.attach_money_rounded;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'food':
        case 'groceries':
          return Icons.restaurant_rounded;
        case 'transport':
          return Icons.directions_car_rounded;
        case 'utilities':
          return Icons.flash_on_rounded;
        case 'entertainment':
          return Icons.movie_rounded;
        case 'shopping':
          return Icons.shopping_bag_rounded;
        case 'skincare':
          return Icons.face_rounded;
        default:
          return Icons.receipt_rounded;
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateFormat('dd/MM/yyyy').parse(dateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));
      DateTime dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM dd').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  void _editTransaction(Map<String, dynamic> transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit transaction: ${transaction['category']}'),
        backgroundColor: const Color(0xFF2D6E5E),
      ),
    );
  }

  void _deleteTransaction(String transactionId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete Transaction',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this transaction?',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(color: const Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await firestoreService.deleteTransaction(transactionId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transaction deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData(); // Refresh data
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting transaction'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FFFE), Color(0xFFF1F9F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Welcome Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back!",
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF1B4B3A),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDateSubtitle(),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Balance Overview Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6E5E), Color(0xFF1B4B3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6E5E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Balance",
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "RM ${totalBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Categories Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Overview",
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF1B4B3A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Income & Expense Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: IncomeExpenseCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: "Income",
                      amount: "RM${totalIncome.toStringAsFixed(2)}",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IncomeExpenseCard(
                      icon: Icons.trending_down_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: "Expense",
                      amount: "RM${totalExpense.toStringAsFixed(2)}",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Transactions Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF1B4B3A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // TextButton(
                  //   onPressed: () {},
                  //   child: Text(
                  //     "View All",
                  //     style: GoogleFonts.montserrat(
                  //       color: const Color(0xFF2D6E5E),
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Cards from Database
            recentTransactions.isEmpty
                ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions yet",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add your first transaction using the + button",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> transaction =
                        recentTransactions[index];
                    String type = transaction['type'] ?? '';
                    bool isIncome = type == 'Income';

                    return TransactionCard(
                      icon: _getIconForCategory(
                        transaction['category'] ?? '',
                        isIncome,
                      ),
                      iconColor:
                          isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                      amount: "RM${transaction['amount']?.toString() ?? '0'}",
                      category: transaction['category'] ?? 'Unknown',
                      date: _formatDate(transaction['date'] ?? ''),
                      onEdit: () => _editTransaction(transaction),
                      onDelete: () => _deleteTransaction(transaction['id']),
                    );
                  },
                ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class IncomeExpenseCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String amount;

  const IncomeExpenseCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4B3A).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4B3A),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String amount;
  final String category;
  final String date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.amount,
    required this.category,
    required this.date,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4B3A).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            amount,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF1B4B3A),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                category,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Color(0xFF2D6E5E),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF2D6E5E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
