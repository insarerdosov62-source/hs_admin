import 'package:flutter/material.dart';
import 'package:honda_admin/firebase_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'service_history_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Чтобы работать с файлом
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  // Основные поля
  final _phoneController = TextEditingController(text: "+7");
  final _carModelController = TextEditingController(text: "Honda");
  final _mileageController = TextEditingController();
  final _oilTypeController = TextEditingController();
  final _nextMileageController = TextEditingController();
  final _otherWorkController = TextEditingController();
  final _otherPriceController = TextEditingController();
  final TextEditingController _plateController =
      TextEditingController(); // Госномер
  String? _photoBeforePath; // Путь к фото ДО
  String? _photoAfterPath; // Путь к фото ПОСЛЕ

  String selectedCategory = "ТО";
  final List<String> categories = [
    "ТО",
    "Ходовая",
    "ДВС",
    "Трансмиссия",
    "Прочее",
  ];

  // --- ПЕРЕМЕННЫЕ СОСТОЯНИЯ ---

  // ТО
  bool oilFilter = false;
  String oilFilterPrice = "";
  String oilFilterComment = "";
  bool airFilter = false;
  String airFilterPrice = "";
  String airFilterComment = "";
  bool cabinFilter = false;
  String cabinFilterPrice = "";
  String cabinFilterComment = "";

  // Ходовая
  bool brakePads = false;
  String brakePadsPrice = "";
  String brakePadsComment = "";
  bool shockAbsorbers = false;
  String shockAbsorbersPrice = "";
  String shockAbsorbersComment = "";
  bool steeringRack = false;
  String steeringRackPrice = "";
  String steeringRackComment = "";

  // ДВС
  bool valveAdjustment = false;
  String valveAdjustmentPrice = "";
  String valveAdjustmentComment = "";
  bool timingBelt = false;
  String timingBeltPrice = "";
  String timingBeltComment = "";
  bool injectorCleaning = false;
  String injectorCleaningPrice = "";
  String injectorCleaningComment = "";

  // Трансмиссия
  bool transmissionFluid = false;
  String transmissionFluidPrice = "";
  String transmissionFluidComment = "";
  bool differentialOil = false;
  String differentialOilPrice = "";
  String differentialOilComment = "";

  // Считаем общую сумму (логика totalPrice из Котлина)
  int get totalPrice {
    int sum = 0;
    if (oilFilter) sum += int.tryParse(oilFilterPrice) ?? 0;
    if (airFilter) sum += int.tryParse(airFilterPrice) ?? 0;
    if (cabinFilter) sum += int.tryParse(cabinFilterPrice) ?? 0;
    if (brakePads) sum += int.tryParse(brakePadsPrice) ?? 0;
    if (shockAbsorbers) sum += int.tryParse(shockAbsorbersPrice) ?? 0;
    if (steeringRack) sum += int.tryParse(steeringRackPrice) ?? 0;
    if (valveAdjustment) sum += int.tryParse(valveAdjustmentPrice) ?? 0;
    if (timingBelt) sum += int.tryParse(timingBeltPrice) ?? 0;
    if (injectorCleaning) sum += int.tryParse(injectorCleaningPrice) ?? 0;
    if (transmissionFluid) sum += int.tryParse(transmissionFluidPrice) ?? 0;
    if (differentialOil) sum += int.tryParse(differentialOilPrice) ?? 0;
    sum += int.tryParse(_otherPriceController.text) ?? 0;
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HONDA SERVICE — Панель администратора",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFCC0000),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                // 1. Открываем историю и ждем клика по кнопке повтора 🔁
                final Map<String, dynamic>? repeatedRecord =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceHistoryScreen(),
                      ),
                    );

                // 2. Если запись выбрали, подставляем данные
                if (repeatedRecord != null) {
                  setState(() {
                    // Закидываем базовые данные машины
                    _carModelController.text =
                        repeatedRecord['carModel'] ?? 'Honda';
                    _plateController.text =
                        repeatedRecord['licensePlate'] ?? '';

                    // Сбрасываем фотки для нового заезда
                    _photoBeforePath = null;
                    _photoAfterPath = null;

                    // Читаем весь текст выполненных работ
                    String details = repeatedRecord['type'] ?? '';

                    // Проверяем, есть ли в тексте хоть одна стандартная галочка
                    bool hasStandardJobs =
                        details.contains("Масляный") ||
                        details.contains("Воздушный") ||
                        details.contains("Салонный") ||
                        details.contains("колодки") ||
                        details.contains("Амортизаторы") ||
                        details.contains("рейка") ||
                        details.contains("клапанов") ||
                        details.contains("ГРМ") ||
                        details.contains("форсунок") ||
                        details.contains("CVT") ||
                        details.contains("редуктор");

                    if (!hasStandardJobs && details.isNotEmpty) {
                      // МУДРОСТЬ ДЛЯ ОЛЬГИ: Если стандартных галочек нет, значит всё написано в ПРОЧЕЕ!
                      // Убираем лишние точки или переносы строк, если они есть по краям
                      _otherWorkController.text = details.trim();

                      // Подставляем общую стоимость из старой записи в цену прочих работ
                      if (repeatedRecord['totalPrice'] != null) {
                        _otherPriceController.text =
                            repeatedRecord['totalPrice'].toString();
                      }

                      // Выключаем все галочки, чтобы ничего лишнего не горело
                      oilFilter = airFilter = cabinFilter = brakePads =
                          shockAbsorbers = steeringRack = valveAdjustment =
                              timingBelt = injectorCleaning =
                                  transmissionFluid = differentialOil = false;
                    } else {
                      // ОБЫЧНЫЙ РЕЖИМ (Если запись была сделана через галочки)
                      oilFilter =
                          details.contains("Масляный") ||
                          details.contains("Ф. масляный");
                      airFilter =
                          details.contains("Воздушный") ||
                          details.contains("Ф. воздушный");
                      cabinFilter =
                          details.contains("Салонный") ||
                          details.contains("Ф. салонный");

                      brakePads =
                          details.contains("колодки") ||
                          details.contains("Торм. колодки");
                      shockAbsorbers = details.contains("Амортизаторы");
                      steeringRack =
                          details.contains("рейка") ||
                          details.contains("Рулевая рейка");

                      valveAdjustment =
                          details.contains("клапанов") ||
                          details.contains("Регулировка клапанов");
                      timingBelt =
                          details.contains("ГРМ") ||
                          details.contains("Замена ГРМ");
                      injectorCleaning =
                          details.contains("форсунок") ||
                          details.contains("Чистка форсунок");

                      transmissionFluid =
                          details.contains("CVT") ||
                          details.contains("вариатора");
                      differentialOil =
                          details.contains("Редуктор") ||
                          details.contains("редуктор");

                      // Очищаем прочее, так как тут работали по галочкам
                      _otherWorkController.clear();
                      _otherPriceController.clear();
                    }

                    // Очищаем пробег и старые цены галочек для новой записи
                    _mileageController.clear();
                    oilFilterPrice = "";
                    airFilterPrice = "";
                    cabinFilterPrice = "";
                    brakePadsPrice = "";
                    shockAbsorbersPrice = "";
                    steeringRackPrice = "";
                    valveAdjustmentPrice = "";
                    timingBeltPrice = "";
                    injectorCleaningPrice = "";
                    transmissionFluidPrice = "";
                    differentialOilPrice = "";
                  });
                }
              },
              icon: const Icon(Icons.history, size: 20),
              label: const Text("ИСТОРИЯ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFCC0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Левая часть: Форма ввода
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Данные клиента"),
                  _buildInput(_phoneController, "Телефон клиента", Icons.phone),
                  const SizedBox(height: 12),
                  _buildInput(
                    _carModelController,
                    "Модель авто",
                    Icons.directions_car,
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    _plateController,
                    "Госномер (например: 777AAA01)",
                    Icons.pin_drop,
                  ),
                  const SizedBox(height: 24),

                  _buildHeader("Категории работ"),
                  Wrap(
                    spacing: 8,
                    children: categories
                        .map(
                          (cat) => ChoiceChip(
                            label: Text(cat),
                            selected: selectedCategory == cat,
                            selectedColor: const Color(0xFFCC0000),
                            labelStyle: TextStyle(
                              color: selectedCategory == cat
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (val) =>
                                setState(() => selectedCategory = cat),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  _buildHeader("Детализация: $selectedCategory"),
                  _buildCategoryFields(),

                  // --- ВОТ ЗДЕСЬ БЫЛА ОШИБКА СО СКОБКОЙ ---
                  const SizedBox(height: 24),
                  _buildHeader("Фотоотчет"),
                  Row(
                    children: [
                      // Колонка ФОТО: ДО
                      Expanded(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(true),
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text("ФОТО: ДО"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ПРЕВЬЮ ДО
                            if (_photoBeforePath != null)
                              _buildImagePreview(
                                path: _photoBeforePath!,
                                onClear: () => setState(
                                  () => _photoBeforePath = null,
                                ), // Сбрасываем в null
                              )
                            else
                              _buildEmptyPreview(), // Заглушка, если фото нет
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Колонка ФОТО: ПОСЛЕ
                      Expanded(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(false),
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text("ФОТО: ПОСЛЕ"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ПРЕВЬЮ ПОСЛЕ
                            if (_photoAfterPath != null)
                              _buildImagePreview(
                                path: _photoAfterPath!,
                                onClear: () => setState(
                                  () => _photoAfterPath = null,
                                ), // Сбрасываем в null
                              )
                            else
                              _buildEmptyPreview(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _uploadAndSave, // Привязываем нашу функцию
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCC0000),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ), // ИСПРАВЛЕНО
                    ),
                    child: const Text(
                      "СОХРАНИТЬ ОТЧЕТ В БАЗУ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ], // Закрываем children Column
              ),
            ),
          ),

          // Правая часть: Предпросмотр (без изменений)
          Container(
            width: 400,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "ПРЕДПРОСМОТР ОТЧЕТА",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _buildReportText(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "ИТОГО: $totalPrice ₸",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC0000),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(Icons.send),
                  label: const Text("ОТПРАВИТЬ В WHATSAPP"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для заголовков секций
  Widget _buildHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  // Виджет для полей ввода
  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon,
  ) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Логика переключения полей в зависимости от категории
  Widget _buildCategoryFields() {
    switch (selectedCategory) {
      case "ТО":
        return Column(
          children: [
            _buildInput(_mileageController, "Текущий пробег", Icons.speed),
            const SizedBox(height: 10),
            _buildInput(_oilTypeController, "Тип масла", Icons.opacity),
            const SizedBox(height: 10),
            _buildInput(
              _nextMileageController,
              "След. замена (км)",
              Icons.event_repeat,
            ),
            const Divider(height: 30),
            _buildServiceRow(
              "Ф. масляный",
              oilFilter,
              (v) => setState(() => oilFilter = v!),
              oilFilterComment,
              (v) => setState(() => oilFilterComment = v),
              oilFilterPrice,
              (v) => setState(() => oilFilterPrice = v),
            ),
            _buildServiceRow(
              "Ф. воздушный",
              airFilter,
              (v) => setState(() => airFilter = v!),
              airFilterComment,
              (v) => setState(() => airFilterComment = v),
              airFilterPrice,
              (v) => setState(() => airFilterPrice = v),
            ),
            _buildServiceRow(
              "Ф. салонный",
              cabinFilter,
              (v) => setState(() => cabinFilter = v!),
              cabinFilterComment,
              (v) => setState(() => cabinFilterComment = v),
              cabinFilterPrice,
              (v) => setState(() => cabinFilterPrice = v),
            ),
          ],
        );

      case "Ходовая":
        return Column(
          children: [
            _buildServiceRow(
              "Торм. колодки",
              brakePads,
              (v) => setState(() => brakePads = v!),
              brakePadsComment,
              (v) => setState(() => brakePadsComment = v),
              brakePadsPrice,
              (v) => setState(() => brakePadsPrice = v),
            ),
            _buildServiceRow(
              "Амортизаторы",
              shockAbsorbers,
              (v) => setState(() => shockAbsorbers = v!),
              shockAbsorbersComment,
              (v) => setState(() => shockAbsorbersComment = v),
              shockAbsorbersPrice,
              (v) => setState(() => shockAbsorbersPrice = v),
            ),
            _buildServiceRow(
              "Рул. рейка",
              steeringRack,
              (v) => setState(() => steeringRack = v!),
              steeringRackComment,
              (v) => setState(() => steeringRackComment = v),
              steeringRackPrice,
              (v) => setState(() => steeringRackPrice = v),
            ),
          ],
        );

      case "ДВС":
        return Column(
          children: [
            _buildServiceRow(
              "Рег. клапанов",
              valveAdjustment,
              (v) => setState(() => valveAdjustment = v!),
              valveAdjustmentComment,
              (v) => setState(() => valveAdjustmentComment = v),
              valveAdjustmentPrice,
              (v) => setState(() => valveAdjustmentPrice = v),
            ),
            _buildServiceRow(
              "Замена ГРМ",
              timingBelt,
              (v) => setState(() => timingBelt = v!),
              timingBeltComment,
              (v) => setState(() => timingBeltComment = v),
              timingBeltPrice,
              (v) => setState(() => timingBeltPrice = v),
            ),
            _buildServiceRow(
              "Чистка форсунок",
              injectorCleaning,
              (v) => setState(() => injectorCleaning = v!),
              injectorCleaningComment,
              (v) => setState(() => injectorCleaningComment = v),
              injectorCleaningPrice,
              (v) => setState(() => injectorCleaningPrice = v),
            ),
          ],
        );

      // ТВОЯ НОВАЯ СЕКЦИЯ ТРАНСМИССИЯ
      case "Трансмиссия":
        return Column(
          children: [
            _buildServiceRow(
              "Жидкость CVT/АКПП",
              transmissionFluid,
              (v) => setState(() => transmissionFluid = v!),
              transmissionFluidComment,
              (v) => setState(() => transmissionFluidComment = v),
              transmissionFluidPrice,
              (v) => setState(() => transmissionFluidPrice = v),
            ),
            _buildServiceRow(
              "Редуктор",
              differentialOil,
              (v) => setState(() => differentialOil = v!),
              differentialOilComment,
              (v) => setState(() => differentialOilComment = v),
              differentialOilPrice,
              (v) => setState(() => differentialOilPrice = v),
            ),
          ],
        );

      case "Прочее":
        return Column(
          children: [
            TextField(
              controller: _otherWorkController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "Описание работ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _buildInput(
              _otherPriceController,
              "Стоимость работ",
              Icons.payments,
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildServiceRow(
    String name,
    bool value,
    Function(bool?) onCheck,
    String comment,
    Function(String) onCommentChange,
    String price,
    Function(String) onPriceChange,
  ) {
    return Column(
      key: ValueKey("row_$name"),
      children: [
        CheckboxListTile(
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          value: value,
          onChanged: onCheck,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(left: 65, right: 16, bottom: 10),
            child: Row(
              children: [
                // Поле комментария
                Expanded(
                  flex: 2,
                  child: TextField(
                    // Используем контроллер, который не ломает ввод при setState
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: comment,
                        selection: TextSelection.collapsed(
                          offset: comment.length,
                        ),
                      ),
                    ),
                    onChanged: onCommentChange,
                    decoration: const InputDecoration(
                      hintText: "Комментарий",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Поле цены
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: price,
                        selection: TextSelection.collapsed(
                          offset: price.length,
                        ),
                      ),
                    ),
                    onChanged: onPriceChange,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Цена",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  String _buildReportText() {
    String report = "🚙 *HONDA SERVICE*\n\n";
    if (_plateController.text.isNotEmpty) {
      report += "Госномер: *${_plateController.text.toUpperCase()}*\n";
    }
    report += "Отчет по авто: *${_carModelController.text.toUpperCase()}*\n";
    if (_phoneController.text.isNotEmpty && _phoneController.text != "+7") {
      report += "📱 Клиент: ${_phoneController.text}\n";
    }

    // --- СЕКЦИЯ ТО ---
    if (oilFilter ||
        airFilter ||
        cabinFilter ||
        _oilTypeController.text.isNotEmpty ||
        _nextMileageController.text.isNotEmpty) {
      report += "\n*--- ТО ---*";
      if (_mileageController.text.isNotEmpty)
        report += "\n📍 Пробег: ${_mileageController.text} км";
      if (_oilTypeController.text.isNotEmpty)
        report += "\n🛢 Масло: ${_oilTypeController.text}";
      if (_nextMileageController.text.isNotEmpty)
        report += "\n📅 *След. замена: ${_nextMileageController.text} км*";

      if (oilFilter)
        report +=
            "\n✅ Ф. масляный ${oilFilterComment.isNotEmpty ? '($oilFilterComment)' : ''}";
      if (airFilter)
        report +=
            "\n✅ Ф. воздушный ${airFilterComment.isNotEmpty ? '($airFilterComment)' : ''}";
      if (cabinFilter)
        report +=
            "\n✅ Ф. салонный ${cabinFilterComment.isNotEmpty ? '($cabinFilterComment)' : ''}";
    }

    // --- СЕКЦИЯ ХОДОВАЯ ---
    if (brakePads || shockAbsorbers || steeringRack) {
      report += "\n\n*--- ХОДОВАЯ ---*";
      if (brakePads)
        report +=
            "\n✅ Тормозные колодки ${brakePadsComment.isNotEmpty ? '($brakePadsComment)' : ''}";
      if (shockAbsorbers)
        report +=
            "\n✅ Амортизаторы ${shockAbsorbersComment.isNotEmpty ? '($shockAbsorbersComment)' : ''}";
      if (steeringRack)
        report +=
            "\n✅ Рулевая рейка ${steeringRackComment.isNotEmpty ? '($steeringRackComment)' : ''}";
    }

    // --- СЕКЦИЯ ДВС ---
    if (valveAdjustment || timingBelt || injectorCleaning) {
      report += "\n\n*--- ДВС ---*";
      if (valveAdjustment)
        report +=
            "\n✅ Регулировка клапанов ${valveAdjustmentComment.isNotEmpty ? '($valveAdjustmentComment)' : ''}";
      if (timingBelt)
        report +=
            "\n✅ Замена ГРМ ${timingBeltComment.isNotEmpty ? '($timingBeltComment)' : ''}";
      if (injectorCleaning)
        report +=
            "\n✅ Чистка форсунок ${injectorCleaningComment.isNotEmpty ? '($injectorCleaningComment)' : ''}";
    }

    // --- СЕКЦИЯ ТРАНСМИССИЯ ---
    if (transmissionFluid || differentialOil) {
      report += "\n\n*--- ТРАНСМИССИЯ ---*";
      if (transmissionFluid)
        report +=
            "\n✅ Жидкость CVT/АКПП ${transmissionFluidComment.isNotEmpty ? '($transmissionFluidComment)' : ''}";
      if (differentialOil)
        report +=
            "\n✅ Редуктор ${differentialOilComment.isNotEmpty ? '($differentialOilComment)' : ''}";
    }

    // --- СЕКЦИЯ ПРОЧЕЕ ---
    if (_otherWorkController.text.isNotEmpty) {
      report += "\n\n*--- ДОПОЛНИТЕЛЬНО ---*";
      String priceTag = _otherPriceController.text.isNotEmpty
          ? " — ${_otherPriceController.text} ₸"
          : "";
      report += "\n🛠 ${_otherWorkController.text.trim()}$priceTag";
    }

    // --- ИТОГО ---
    report += "\n\n*----------------------------*";
    if (totalPrice > 0) {
      report += "\n💰 *ИТОГО К ОПЛАТЕ: $totalPrice ₸*";
    } else {
      report += "\n💰 *Стоимость уточняйте у мастера*";
    }

    return report;
  }

  void _sendWhatsApp() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(_buildReportText())}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _saveReport() {
    // Логика перехода в окно всех отчетов
    print("Сохраняем отчет для госномера: ${_plateController.text}");
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AllReportsScreen()));
  }

  void _pickImage(bool isBefore) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Только эти расширения
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isBefore) {
          _photoBeforePath = result.files.single.path;
        } else {
          _photoAfterPath = result.files.single.path;
        }
      });
    }
  }

  Widget _buildEmptyPreview() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  Widget _buildImagePreview({
    required String path,
    required VoidCallback onClear,
  }) {
    return Stack(
      children: [
        // Само изображение (нижний слой)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Кнопка крестика (верхний слой, прижат к правому верхнему углу)
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onClear, // При нажатии вызываем сброс
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // Полупрозрачный фон
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadAndSave() async {
    // 1. Показываем загрузку
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFCC0000)),
      ),
    );

    try {
      // 1. Подготовка номера
      String plate = _plateController.text.trim().toUpperCase();
      if (plate.isEmpty) {
        Navigator.pop(context); // ДОБАВЬ ЭТО, чтобы закрыть крутилку
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Введите госномер!")));
        return;
      }

      // 2. Параллельная загрузка фото (Быстро и надежно)
      // Мы запускаем обе загрузки одновременно. Если фото нет, передаем пустую строку.
      List<String?> urls = await Future.wait([
        FirebaseManager.uploadImage(_photoBeforePath ?? "", plate),
        FirebaseManager.uploadImage(_photoAfterPath ?? "", plate),
      ]);

      // Достаем результаты. Если вернулся null, записываем "", чтобы не ломать базу.
      String urlBefore = urls[0] ?? "";
      String urlAfter = urls[1] ?? "";

      // Вспомогательная функция для формирования текста (локально внутри метода)
      String addJob(String jobName, String comment) {
        return comment.trim().isNotEmpty
            ? "• $jobName (ком: ${comment.trim()})"
            : "• $jobName";
      }

      // --- 3. ФОРМИРОВАНИЕ ОТЧЕТА (ПОД ТВОИ ПЕРЕМЕННЫЕ) ---
      List<String> historyText = [];

      // СЕКЦИЯ ТО
      if (oilFilter ||
          airFilter ||
          cabinFilter ||
          _oilTypeController.text.trim().isNotEmpty) {
        List<String> toJobs = [];
        if (_oilTypeController.text.trim().isNotEmpty) {
          toJobs.add("• Масло: ${_oilTypeController.text.trim()}");
        }
        if (oilFilter) toJobs.add(addJob("Ф. масляный", oilFilterComment));
        if (airFilter) toJobs.add(addJob("Ф. воздушный", airFilterComment));
        if (cabinFilter) toJobs.add(addJob("Ф. салонный", cabinFilterComment));
        if (_nextMileageController.text.trim().isNotEmpty) {
          toJobs.add(
            "• След. замена: ${_nextMileageController.text.trim()} км",
          );
        }
        historyText.add(
          "ТО (${_mileageController.text} км):\n${toJobs.join("\n")}",
        );
      }

      // СЕКЦИЯ ХОДОВАЯ
      if (brakePads || shockAbsorbers || steeringRack) {
        List<String> sJobs = [];
        if (brakePads) sJobs.add(addJob("Торм. колодки", brakePadsComment));
        if (shockAbsorbers)
          sJobs.add(addJob("Амортизаторы", shockAbsorbersComment));
        if (steeringRack) sJobs.add(addJob("Рул. рейка", steeringRackComment));
        historyText.add("ХОДОВАЯ:\n${sJobs.join("\n")}");
      }

      // СЕКЦИЯ ДВС
      if (valveAdjustment || timingBelt || injectorCleaning) {
        List<String> eJobs = [];
        if (valveAdjustment)
          eJobs.add(addJob("Рег. клапанов", valveAdjustmentComment));
        if (timingBelt) eJobs.add(addJob("Замена ГРМ", timingBeltComment));
        if (injectorCleaning)
          eJobs.add(addJob("Чистка форсунок", injectorCleaningComment));
        historyText.add("ДВС:\n${eJobs.join("\n")}");
      }

      // ТРАНСМИССИЯ
      if (transmissionFluid || differentialOil) {
        List<String> tJobs = [];
        if (transmissionFluid)
          tJobs.add(addJob("Жидкость CVT/АКПП", transmissionFluidComment));
        if (differentialOil)
          tJobs.add(addJob("Редуктор", differentialOilComment));
        historyText.add("ТРАНСМИССИЯ:\n${tJobs.join("\n")}");
      }

      // ПРОЧЕЕ
      if (_otherWorkController.text.trim().isNotEmpty) {
        historyText.add("ПРОЧЕЕ:\n• ${_otherWorkController.text.trim()}");
      }

      // --- РАСЧЕТ ОБЩЕЙ СУММЫ ---

      // Собираем все цены в один список
      List<String> allPrices = [
        oilFilterPrice, airFilterPrice, cabinFilterPrice,
        brakePadsPrice, shockAbsorbersPrice, steeringRackPrice,
        valveAdjustmentPrice, timingBeltPrice, injectorCleaningPrice,
        transmissionFluidPrice, differentialOilPrice,
        _otherPriceController.text, // И последнее поле из "Прочее"
      ];

      // Суммируем
      int totalSum = allPrices.fold(0, (sum, item) {
        // Убираем лишние пробелы и парсим в число. Если пусто или ошибка — берем 0.
        return sum + (int.tryParse(item.trim()) ?? 0);
      });

      // --- ДОБАВЛЕНИЕ В ОТЧЕТ ---

      // Теперь подставляем нашу посчитанную сумму totalSum
      historyText.add("Итого: $totalSum ₸");

      // А в объект для Firebase (newServiceEntry) тоже запиши totalSum
      // 'totalPrice': totalSum,

      String serviceDetails = historyText.join("\n\n");

      // 4. Создаем объект заезда
      Map<String, dynamic> newServiceEntry = {
        'carModel': _carModelController.text,
        'date':
            "${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}",
        'licensePlate': plate,
        'photoUriAfter': urlAfter,
        'photoUriBefore': urlBefore,
        'time':
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'totalPrice': totalSum,
        'type': serviceDetails, // Передаем нашу собранную строку
      };

      // 5. Сохраняем в коллекцию services (Универсальный метод: создаст или обновит)
      DocumentReference serviceRef = FirebaseFirestore.instance
          .collection('services')
          .doc(plate);

      // Сначала проверяем, есть ли такой документ вообще
      var docSnapshot = await serviceRef.get();

      if (!docSnapshot.exists) {
        // Если машины НЕТ, создаем документ и кладем массив с первой записью
        await serviceRef.set({
          'history': [newServiceEntry],
        });
      } else {
        // Если машина ЕСТЬ, просто добавляем новую запись в массив через arrayUnion
        await serviceRef.update({
          'history': FieldValue.arrayUnion([newServiceEntry]),
        });
      }

      // 6. ОТПРАВЛЯЕМ ПУШ (как в Котлине)
      await FirebaseManager.sendPush(plate);

      Navigator.pop(context); // Убираем крутилку
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Готово! История обновлена, пуш отправлен"),
        ),
      );

      // Очищаем поля (кроме номера телефона и модели, чтобы админу было удобнее)
      setState(() {
        _photoBeforePath = null;
        _photoAfterPath = null;
        _mileageController.clear();
        _otherWorkController.clear();
        _otherPriceController.clear();
      });
    } catch (e) {
      Navigator.pop(context);
      print("Ошибка: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Ошибка: $e")));
    }
  }

  void _populateFieldsFromHistory(Map<String, dynamic> record) {
    setState(() {
      // 1. Подставляем основные данные автомобиля и клиента
      _carModelController.text = record['carModel'] ?? 'Honda';
      _plateController.text = record['licensePlate'] ?? '';

      // Если у тебя в истории сохраняется номер телефона, раскомментируй строку ниже:
      // _phoneController.text = record['phone'] ?? '+7';

      // 2. Сбрасываем старые фотографии, так как при повторной записи
      // фотографии "До" и "После" должны быть новые!
      _photoBeforePath = null;
      _photoAfterPath = null;

      // 3. Восстанавливаем галочки услуг, которые были выбраны в прошлый раз.
      // Смотрим на текст из поля 'type', который формируется при сохранении.
      String details = record['type'] ?? '';

      // Ищем упоминания услуг в тексте истории
      oilFilter = details.contains(". "); // Масляный фильтр
      airFilter = details.contains(". "); // Воздушный фильтр
      cabinFilter = details.contains(". "); // Салонный фильтр

      brakePads = details.contains(". "); // Тормозные колодки
      shockAbsorbers = details.contains(
        "",
      ); // Амортизаторы (впиши точное название услуги)
      steeringRack = details.contains(". "); // Рулевая рейка

      valveAdjustment = details.contains(". "); // Регулировка клапанов
      timingBelt = details.contains(" "); // Ремень ГРМ
      injectorCleaning = details.contains(" "); // Чистка форсунок

      transmissionFluid = details.contains(" CVT/"); // Жидкость вариатора
      differentialOil = details.contains(""); // Масло в редуктор

      // 4. Очищаем пробег и прочие работы, чтобы админ вбил актуальные данные руками
      _mileageController.clear();
      _otherWorkController.clear();
      _otherPriceController.clear();

      // Если нужно сбросить цены прошлых запчастей, чтобы админ ввел их заново:
      oilFilterPrice = "";
      airFilterPrice = "";
      cabinFilterPrice = "";
      brakePadsPrice = "";
      shockAbsorbersPrice = "";
      steeringRackPrice = "";
      valveAdjustmentPrice = "";
      timingBeltPrice = "";
      injectorCleaningPrice = "";
      transmissionFluidPrice = "";
      differentialOilPrice = "";
    });
  }
}
