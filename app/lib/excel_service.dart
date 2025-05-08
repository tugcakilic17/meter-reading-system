import 'package:http/http.dart' as http;
import 'dart:convert';

class ExcelService {
  final String apiUrl;

  ExcelService(this.apiUrl);

  Future<String> sendToExcel(String sayacNumarasi, String sayacDegeri) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sayac_numarasi": sayacNumarasi,
          "sayac_degeri": sayacDegeri,
        }),
      );

      if (response.statusCode == 200) {
        return "Veriler başarıyla Excel'e kaydedildi.";
      } else {
        return "API isteği başarısız oldu: ${response.body}";
      }
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }
}
