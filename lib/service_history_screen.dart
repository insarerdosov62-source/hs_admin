import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:honda_admin/pdf_generator.dart';

class ServiceHistoryScreen extends StatefulWidget {
  @override
  _ServiceHistoryScreenState createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  String searchQuery = "";
  final Color hondaRed = Color(0xFFE31837); // Твой фирменный красный
  String selectedDateFilter = ""; // Пустая строка — значит показываем всё

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedDateFilter.isEmpty
              ? "История"
              : "Отчеты за $selectedDateFilter",
        ),
        actions: [
          if (selectedDateFilter.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => selectedDateFilter = ""),
            ),
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ПОЛЕ ПОИСКА
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => searchQuery = value.toUpperCase()),
              decoration: InputDecoration(
                hintText: "Поиск по модели или госномеру",
                prefixIcon: Icon(Icons.search, color: hondaRed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: hondaRed, width: 2),
                ),
              ),
            ),
          ),

          // СПИСОК ИЗ FIRESTORE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                List<Map<String, dynamic>> allRecords = [];
                for (var doc in snapshot.data!.docs) {
                  var history = List<Map<String, dynamic>>.from(
                    doc['history'] ?? [],
                  );
                  allRecords.addAll(history);
                }

                // УМНАЯ СОРТИРОВКА
                allRecords.sort((a, b) {
                  List<String> datePartsA = a['date'].split('.');
                  List<String> datePartsB = b['date'].split('.');

                  String sortKeyA =
                      "${datePartsA[2]}${datePartsA[1]}${datePartsA[0]}${a['time']}";
                  String sortKeyB =
                      "${datePartsB[2]}${datePartsB[1]}${datePartsB[0]}${b['time']}";

                  return sortKeyB.compareTo(sortKeyA);
                });

                // УМНАЯ ФИЛЬТРАЦИЯ
                var filtered = allRecords.where((r) {
                  bool matchesDate =
                      selectedDateFilter.isEmpty ||
                      r['date'] == selectedDateFilter;

                  final query = searchQuery.toLowerCase();
                  bool matchesSearch =
                      r['carModel'].toString().toLowerCase().contains(query) ||
                      r['licensePlate'].toString().toLowerCase().contains(
                        query,
                      );

                  return matchesDate && matchesSearch;
                }).toList();

                if (filtered.isEmpty)
                  return Center(child: Text("Ничего не найдено"));

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      ServiceHistoryCard(record: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      String formatted =
          "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";

      setState(() {
        selectedDateFilter = formatted;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Фильтр установлен: $formatted"),
          action: SnackBarAction(
            label: "Сбросить",
            onPressed: () => setState(() => selectedDateFilter = ""),
          ),
        ),
      );
    }
  }
}

class ServiceHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const ServiceHistoryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: const Color(0xFFE31837)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${record['date']} • ${record['time']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          record['carModel'] ?? "",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record['licensePlate'] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE31837),
                          ),
                        ),
                        const Divider(),
                        Text(
                          record['type'] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                // ТУТ НАШ БЛОК С КНОПКАМИ ДЕЙСТВИЙ
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // СВЕЖАЯ ФИЧА: Кнопка повтора записи 🔁
                    IconButton(
                      icon: const Icon(
                        Icons.repeat,
                        color: Colors.blue,
                      ), // Сделал синей для заметности
                      tooltip: "Повторить запись",
                      onPressed: () {
                        // Закрываем экран истории и отдаем данные record назад на главный экран
                        Navigator.pop(context, record);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.grey),
                      onPressed: () {
                        print("Отправка в генератор...");
                        PdfGenerator.generateAndSharePdf(record)
                            .then((_) {
                              print("Генерация завершена успешно");
                            })
                            .catchError((e) {
                              print("ОШИБКА ПОЙМАНА: $e");
                            });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => showDeleteConfirmation(context, record),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (record['photoUriBefore'] != "" || record['photoUriAfter'] != "")
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  if (record['photoUriBefore'] != "")
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: record['photoUriBefore'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  if (record['photoUriAfter'] != "")
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: record['photoUriAfter'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> deleteRecord(
    Map<String, dynamic> record,
    BuildContext context,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('services')
          .doc(record['licensePlate']);

      await docRef.update({
        'history': FieldValue.arrayRemove([record]),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Запись удалена")));
      }
    } catch (e) {
      print("Ошибка удаления: $e");
    }
  }

  void showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Удаление"),
          content: const Text(
            "Вы уверены, что хотите удалить этот отчет? Это действие нельзя будет отменить.",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Отмена", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31837),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteRecord(record, context);
              },
              child: const Text(
                "Удалить",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
