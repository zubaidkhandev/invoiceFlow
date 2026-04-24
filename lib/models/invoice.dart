import 'package:invoice_flow/models/client_info.dart';
import 'package:invoice_flow/models/line_item.dart';
import 'package:invoice_flow/models/sender_info.dart';

enum InvoiceStatus { draft, unpaid, paid }

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final SenderInfo sender;
  final ClientInfo client;
  final List<LineItem> items;
  final double taxPercentage;
  final String notes;
  final InvoiceStatus status;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.sender,
    required this.client,
    required this.items,
    this.taxPercentage = 0,
    this.notes = '',
    this.status = InvoiceStatus.draft,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.amount);
  double get taxAmount => subtotal * (taxPercentage / 100);
  double get total => subtotal + taxAmount;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    SenderInfo? sender,
    ClientInfo? client,
    List<LineItem>? items,
    double? taxPercentage,
    String? notes,
    InvoiceStatus? status,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      sender: sender ?? this.sender,
      client: client ?? this.client,
      items: items ?? this.items,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'sender': sender.toJson(),
        'client': client.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'taxPercentage': taxPercentage,
        'notes': notes,
        'status': status.name,
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        invoiceNumber: json['invoiceNumber'] as String,
        issueDate: DateTime.parse(json['issueDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        sender: SenderInfo.fromJson(json['sender'] as Map<String, dynamic>),
        client: ClientInfo.fromJson(json['client'] as Map<String, dynamic>),
        items: (json['items'] as List)
            .map((i) => LineItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        taxPercentage: (json['taxPercentage'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
        status: InvoiceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => InvoiceStatus.draft,
        ),
      );
}
