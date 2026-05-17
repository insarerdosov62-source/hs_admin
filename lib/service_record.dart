class ServiceRecord {
  final int? id;
  final String clientName;
  final String phoneNumber;
  final String carModel;
  final String workDescription;
  final double price;
  final String date;

  ServiceRecord({
    this.id,
    required this.clientName,
    required this.phoneNumber,
    required this.carModel,
    required this.workDescription,
    required this.price,
    required this.date,
  });

  // Превращаем данные из базы (Map) в объект Dart
  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'],
      clientName: map['clientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      carModel: map['carModel'] ?? '',
      workDescription: map['workDescription'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      date: map['date'] ?? '',
    );
  }
}
