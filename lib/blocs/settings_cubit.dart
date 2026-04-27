import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/models/sender_info.dart';
import 'package:invoice_flow/services/storage_service.dart';

class SettingsState {
  final SenderInfo sender;
  final String currency;
  final bool isDarkMode;

  const SettingsState({
    required this.sender,
    this.currency = 'USD',
    this.isDarkMode = false,
  });

  SettingsState copyWith({
    SenderInfo? sender,
    String? currency,
    bool? isDarkMode,
  }) {
    return SettingsState(
      sender: sender ?? this.sender,
      currency: currency ?? this.currency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'sender': sender.toJson(),
        'currency': currency,
        'isDarkMode': isDarkMode,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        sender: SenderInfo.fromJson(Map<String, dynamic>.from(json['sender'])),
        currency: json['currency'] as String? ?? 'USD',
        isDarkMode: json['isDarkMode'] as bool? ?? false,
      );
}

class SettingsCubit extends Cubit<SettingsState> {
  final StorageService _storageService;

  SettingsCubit(this._storageService)
      : super(const SettingsState(sender: SenderInfo())) {
    _loadSettings();
  }

  void _loadSettings() {
    final data = _storageService.getSettings();
    if (data != null) {
      emit(SettingsState.fromJson(data));
    }
  }

  Future<void> updateSender(SenderInfo sender) async {
    final newState = state.copyWith(sender: sender);
    emit(newState);
    await _storageService.saveSettings(newState.toJson());
  }

  Future<void> updateCurrency(String currency) async {
    final newState = state.copyWith(currency: currency);
    emit(newState);
    await _storageService.saveSettings(newState.toJson());
  }

  Future<void> toggleDarkMode() async {
    final newState = state.copyWith(isDarkMode: !state.isDarkMode);
    emit(newState);
    await _storageService.saveSettings(newState.toJson());
  }
}
