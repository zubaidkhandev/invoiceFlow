import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('invoice_flow_box');
  }

  // History Logging
  List<dynamic> getHistory() => _box.get('history', defaultValue: []);
  Future<void> saveHistoryItem(Map<String, dynamic> item) async {
    final history = List.from(getHistory());
    history.add(item);
    await _box.put('history', history);
  }

  // App Security (Password Lock)
  bool hasAppPassword() => _box.containsKey('app_password');
  String? getPassword() => _box.get('app_password');
  Future<void> savePassword(String? password) async {
    if (password == null) {
      await _box.delete('app_password');
    } else {
      await _box.put('app_password', password);
    }
  }

  // Business Profile / Sender Info
  Map<String, dynamic>? getSender() => _box.get('sender');
  Future<void> saveSender(Map<String, dynamic> sender) async {
    await _box.put('sender', sender);
  }

  // Invoice Data
  List<dynamic> getInvoices() => _box.get('invoices', defaultValue: []);
  Future<void> saveInvoices(List<dynamic> invoices) async {
    await _box.put('invoices', invoices);
  }

  // Client Directory
  List<dynamic> getClients() => _box.get('clients', defaultValue: []);
  Future<void> saveClients(List<dynamic> clients) async {
    await _box.put('clients', clients);
  }

  // App Settings (Currency, Dark Mode)
  Map<String, dynamic>? getSettings() => _box.get('settings');
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _box.put('settings', settings);
  }
}
