import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class TransactionService {
  // ⚠️ Chạy Android emulator thì dùng 10.0.2.2 thay vì localhost
  final String baseUrl =
      "http://10.0.2.2:5000/api/transactions/getTransaction";

  Future<List<TransactionModel>> getTransactions() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Map sang TransactionModel
      return data.map((t) => TransactionModel.fromJson(t)).toList();
    } else {
      throw Exception("Failed to load transactions: ${response.statusCode}");
    }
  }
}
