import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get user-specific collection references
  CollectionReference get transactions {
    if (!isAuthenticated) throw Exception('User not authenticated');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId!)
        .collection('transactions');
  }

  CollectionReference get categories {
    if (!isAuthenticated) throw Exception('User not authenticated');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId!)
        .collection('categories');
  }

  // CREATE: add new transaction
  Future<void> addTransaction(
    int amount,
    String category,
    String date,
    String type,
  ) async {
    try {
      await transactions.add({
        'amount': amount,
        'category': category,
        'date': date,
        'type': type,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // CATEGORY MANAGEMENT FUNCTIONS

  // CREATE: add new category
  Future<void> addCategory(String categoryName, String type) async {
    try {
      await categories.add({
        'name': categoryName,
        'type': type, // 'Expense' or 'Income'
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // READ: get categories by type
  Stream<QuerySnapshot> getCategories(String type) {
    return categories.where('type', isEqualTo: type).snapshots();
  }

  // DELETE: delete category given a doc id
  Future<void> deleteCategory(String docID) async {
    try {
      await categories.doc(docID).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // UPDATE: update category given a doc id
  Future<void> updateCategory(String docID, String newName) async {
    try {
      await categories.doc(docID).update({'name': newName});
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // READ: get all transactions
  Stream<QuerySnapshot> getAllTransactions() {
    return transactions.snapshots();
  }

  // READ: get recent transactions (limited)
  Stream<QuerySnapshot> getRecentTransactions(int limit) {
    return transactions
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // READ: get transactions by date
  Stream<QuerySnapshot> getTransactionsByDate(String date) {
    return transactions.where('date', isEqualTo: date).snapshots();
  }

  // DELETE: delete transaction given a doc id
  Future<void> deleteTransaction(String docID) async {
    try {
      await transactions.doc(docID).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // READ: get transaction from database

  // UPDATE: update transaction given a doc id

  // DELETE: delete transaction given a doc id
}
