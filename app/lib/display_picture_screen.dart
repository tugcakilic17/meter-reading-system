import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'excel_update_service.dart'; 

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  TextEditingController firstModelController = TextEditingController();
  TextEditingController secondModelController = TextEditingController();
  final ExcelUpdateService excelUpdateService = ExcelUpdateService();
  String selectedBlock = 'A'; 
  String selectedMonth = 'Ocak'; 
  Map<String, String>? ocrResult; 
  bool isLoading = true; 

  bool isEditingFirstModel = false; 
  bool isEditingSecondModel = false; 

  @override
  void initState() {
    super.initState();
    _loadOCRResult();
  }

  Future<void> _loadOCRResult() async {
    final bytes = File(widget.imagePath).readAsBytesSync();
    String base64Image = base64Encode(bytes);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.52:5000/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          String firstModelNumber =
              result['first_model_numbers'] ?? "Belirlenemedi";
          String secondModelText =
              result['second_model_text'] ?? "Belirlenemedi"; 

          // Eğer sayı uzunluğu uygunsa nokta ekle
          if (!firstModelNumber.contains('.') && firstModelNumber.length > 3) {
            int len = firstModelNumber.length;
            firstModelNumber =
                '${firstModelNumber.substring(0, len - 3)}.${firstModelNumber.substring(len - 3)}';
          }

          ocrResult = {
            "firstModelNumber": firstModelNumber,
            "secondModelNumber": secondModelText, 
          };
          firstModelController.text =
              firstModelNumber; 
          secondModelController.text =
              secondModelText; 

          isLoading = false;
        });
      } else {
        setState(() {
          ocrResult = {
            "error":
                "API isteği başarısız oldu. Durum Kodu: ${response.statusCode}"
          };
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        ocrResult = {"error": "Bir hata oluştu: $e"};
        isLoading = false;
      });
    }
  }

  Future<void> _updateExcel() async {
    if (ocrResult == null ||
        ocrResult!['secondModelNumber'] == null ||
        ocrResult!['firstModelNumber'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR sonuçları eksik!')),
      );
      return;
    }

    // Noktadan sonrasını çıkarmak
    final String rawValue = ocrResult!['firstModelNumber']!;
    final String kwhValue = rawValue.split('.')[0]; 
    final officeNo = ocrResult!['secondModelNumber']!;
    final block = "$selectedBlock BLOK";
    final month = selectedMonth.toUpperCase();

    // Gönderilen JSON'u yazdır
    print("Gönderilen JSON:");
    print({
      "block": block,
      "office_no": officeNo,
      "month": month,
      "kwh_value": kwhValue, 
    });

    // API isteği gönder
    try {
      final response = await excelUpdateService.updateExcel(
        block: block,
        officeNo: officeNo,
        month: month,
        kwhValue: kwhValue,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraf Önizleme'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Yükleniyorsa spinner göster
          : ocrResult == null || ocrResult!['error'] != null
              ? Center(
                  child: Text(
                    ocrResult?['error'] ?? 'Bilinmeyen bir hata oluştu.',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fotoğraf
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(File(widget.imagePath)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sayaç Bilgileri
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'kWh: ',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    isEditingFirstModel
                                        ? SizedBox(
                                            width:
                                                100, // Düzenleme kutusunun genişliği
                                            child: TextField(
                                              controller:
                                                  firstModelController, // Controller atanıyor
                                              autofocus: true,
                                              onSubmitted: (value) {
                                                setState(() {
                                                  ocrResult![
                                                          'firstModelNumber'] =
                                                      value;
                                                  isEditingFirstModel = false;
                                                });
                                              },
                                            ),
                                          )
                                        : Text(
                                            ocrResult!['firstModelNumber']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF002244),
                                            ),
                                          ),
                                  ],
                                ),
                                SizedBox(
                                  height: 24, // Buton yüksekliği
                                  width: 24, // Buton genişliği
                                  child: IconButton(
                                    padding: EdgeInsets
                                        .zero, // Ekstra boşlukları kaldırır
                                    icon: Icon(
                                      isEditingFirstModel
                                          ? Icons.check
                                          : Icons.edit,
                                      size: 20, // Simge boyutu
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isEditingFirstModel =
                                            !isEditingFirstModel;
                                        if (!isEditingFirstModel) {
                                          // Düzenleme kapatılıyorsa
                                          ocrResult!['firstModelNumber'] =
                                              firstModelController
                                                  .text; // Yeni değer kaydediliyor
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Sayaç Numarası: ',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    isEditingSecondModel
                                        ? SizedBox(
                                            width:
                                                100, // Düzenleme kutusunun genişliği
                                            child: TextField(
                                              controller:
                                                  secondModelController, // Controller atanıyor
                                              autofocus: true,
                                              onSubmitted: (value) {
                                                setState(() {
                                                  ocrResult![
                                                          'secondModelNumber'] =
                                                      value;
                                                  isEditingSecondModel = false;
                                                });
                                              },
                                            ),
                                          )
                                        : Text(
                                            ocrResult!['secondModelNumber']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF002244),
                                            ),
                                          ),
                                  ],
                                ),
                                SizedBox(
                                  height: 24, // Buton yüksekliği
                                  width: 24, // Buton genişliği
                                  child: IconButton(
                                    padding: EdgeInsets
                                        .zero, // Ekstra boşlukları kaldırır
                                    icon: Icon(
                                      isEditingSecondModel
                                          ? Icons.check
                                          : Icons.edit,
                                      size: 20, // Simge boyutu
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isEditingSecondModel =
                                            !isEditingSecondModel;
                                        if (!isEditingSecondModel) {
                                          // Düzenleme kapatılıyorsa
                                          ocrResult!['secondModelNumber'] =
                                              secondModelController
                                                  .text; // Yeni değer kaydediliyor
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Dropdown Menüleri
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCE7FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: selectedBlock,
                                isExpanded: true,
                                underline: Container(),
                                items: [
                                  'A',
                                  'B',
                                  'C',
                                  'D',
                                  'E',
                                  'F',
                                  'G',
                                  'H',
                                  'I',
                                  'J',
                                  'K',
                                  'ROSEM'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedBlock = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCE7FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: selectedMonth,
                                isExpanded: true,
                                underline: Container(),
                                items: [
                                  'Ocak',
                                  'Şubat',
                                  'Mart',
                                  'Nisan',
                                  'Mayıs',
                                  'Haziran',
                                  'Temmuz',
                                  'Ağustos',
                                  'Eylül',
                                  'Ekim',
                                  'Kasım',
                                  'Aralık'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMonth = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Yazdır Butonu
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: FloatingActionButton(
                            onPressed: _updateExcel,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.print),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    firstModelController.dispose();
    secondModelController.dispose();
    super.dispose();
  }
}
