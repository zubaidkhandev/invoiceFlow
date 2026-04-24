import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/models/history_item.dart';
import 'package:invoice_flow/services/storage_service.dart';
import 'package:uuid/uuid.dart';

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<HistoryItem> items;
  HistoryLoaded(this.items);
}

class HistoryCubit extends Cubit<HistoryState> {
  final StorageService _storageService;

  HistoryCubit(this._storageService) : super(HistoryInitial());

  void loadHistory() {
    emit(HistoryLoading());
    final raw = _storageService.getHistory();
    final items = raw.map((e) => HistoryItem.fromJson(e)).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    emit(HistoryLoaded(items));
  }

  Future<void> logAction({
    required String title,
    required String description,
    required String type,
  }) async {
    final item = HistoryItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
    );

    await _storageService.saveHistoryItem(item.toJson());
    loadHistory();
  }
}
