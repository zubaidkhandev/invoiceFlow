class HistoryItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type;

  const HistoryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: json['type'] as String,
      );
}
