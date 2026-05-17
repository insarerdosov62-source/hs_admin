import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class FirebaseManager {
  static Future<String?> uploadImage(String filePath, String plate) async {
    if (filePath.isEmpty) return "";

    try {
      // Данные из твоего Cloudinary (скрин 13.00.45)
      String cloudName = "dswdz9se1";
      String uploadPreset = "ml_default";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print("📤 Отправляем фото в Cloudinary...");

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonRes = jsonDecode(responseString);

      if (response.statusCode == 200) {
        String url = jsonRes['secure_url'];
        print("✅ Ссылка получена: $url");
        return url;
      } else {
        print(
          "❌ Ошибка Cloudinary: ${jsonRes['error']?['message'] ?? responseString}",
        );
        return "";
      }
    } catch (e) {
      print("❌ Ошибка сети: $e");
      return "";
    }
  }

  // --- 2. Отправка Пуша (аналог sendPushNotification) ---
  static Future<void> sendPush(String licensePlate) async {
    try {
      // Ищем токен клиента в коллекции cars
      var doc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(licensePlate.toUpperCase())
          .get();
      String? token = doc.data()?['fcmToken'];

      if (token != null && token.isNotEmpty) {
        await _triggerFcmV1(token, licensePlate.toUpperCase());
      } else {
        print("Токен для $licensePlate не найден");
      }
    } catch (e) {
      print("Ошибка FCM: $e");
    }
  }

  // --- 3. Внутрянка FCM V1 ---
  static Future<void> _triggerFcmV1(String token, String plate) async {
    // Грузим ключи из ассетов
    final jsonKey = await rootBundle.loadString('assets/service_account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonKey);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);

    final String url =
        "https://fcm.googleapis.com/v1/projects/honda-service-d4107/messages:send";

    final payload = {
      "message": {
        "token": token,
        "notification": {
          "title": "HS Service",
          "body": "Ваша история обслуживания обновлена (номер $plate)",
        },
        "android": {
          "notification": {"channel_id": "high_importance_channel"},
        },
      },
    };

    final response = await client.post(
      Uri.parse(url),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print("Пуш улетел успешно!");
    } else {
      print("Ошибка пуша: ${response.body}");
    }
    client.close();
  }
}
