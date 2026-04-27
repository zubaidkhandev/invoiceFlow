import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/history_cubit.dart';
import 'package:invoice_flow/models/invoice.dart';
import 'package:invoice_flow/services/storage_service.dart';

abstract class InvoiceState {}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<Invoice> invoices;
  InvoiceLoaded(this.invoices);
}

class InvoiceCubit extends Cubit<InvoiceState> {
  final StorageService _storageService;
  final HistoryCubit _historyCubit;

  InvoiceCubit(this._storageService, this._historyCubit)
      : super(InvoiceInitial());

  Future<void> loadInvoices() async {
    emit(InvoiceLoading());
    try {
      final data = _storageService.getInvoices();
      final invoices = data
          .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceLoaded(const []));
    }
  }

  Future<void> saveInvoice(Invoice invoice) async {
    final data = _storageService.getInvoices();
    final index = data.indexWhere((e) => e['id'] == invoice.id);
    
    if (index >= 0) {
      data[index] = invoice.toJson();
    } else {
      data.add(invoice.toJson());
    }

    await _storageService.saveInvoices(data);
    
    _historyCubit.logAction(
      title: index >= 0 ? 'Invoice Updated' : 'Invoice Created',
      description: 'Invoice #${invoice.invoiceNumber} for ${invoice.client.name}',
      type: 'invoice',
    );

    await loadInvoices();
  }

  Future<void> updateStatus(Invoice invoice, InvoiceStatus status) async {
    final updatedInvoice = invoice.copyWith(status: status);
    await saveInvoice(updatedInvoice);
  }

  Future<void> deleteInvoice(String id) async {
    final data = _storageService.getInvoices();
    final index = data.indexWhere((e) => e['id'] == id);
    if (index >= 0) {
      final invoiceNum = data[index]['invoiceNumber'];
      data.removeAt(index);
      await _storageService.saveInvoices(data);
      
      _historyCubit.logAction(
        title: 'Invoice Deleted',
        description: 'Invoice #$invoiceNum was removed',
        type: 'invoice',
      );
      
      await loadInvoices();
    }
  }
}
