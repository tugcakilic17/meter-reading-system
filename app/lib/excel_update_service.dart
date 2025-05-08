import 'dart:convert';
import 'package:http/http.dart' as http;

class ExcelUpdateService {
  final String apiUrl =
      'http://192.168.1.52:5000/update_excel'; 

  Future<String> updateExcel({
    required String block,
    required String officeNo,
    required String month,
    required String kwhValue, 
  }) async {
    try {
      final int parsedKwhValue = int.parse(kwhValue);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "block": block.toUpperCase(),
          "office_no": officeNo,
          "month": month.toUpperCase(),
          "kwh_value": parsedKwhValue, 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['message'];
      } else {
        return jsonDecode(response.body)['error'];
      }
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
  }
  
}
