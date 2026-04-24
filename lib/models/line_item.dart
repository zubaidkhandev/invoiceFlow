class LineItem {
  final String description;
  final double quantity;
  final double unitPrice;

  const LineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  factory LineItem.empty() => const LineItem(
        description: '',
        quantity: 1,
        unitPrice: 0,
      );

  double get amount => quantity * unitPrice;

  LineItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
  }) {
    return LineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(
        description: json['description'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );
}
