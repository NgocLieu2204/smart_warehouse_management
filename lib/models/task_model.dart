// Lớp con để xử lý đối tượng "payload"
class Payload {
  final String sku;
  final String wh;

  Payload({required this.sku, required this.wh});

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      sku: json['sku'] as String,
      wh: json['wh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'wh': wh,
    };
  }
}

class Task {
  final String id;
  final String type;
  final String status;
  final String priority;
  final Payload payload;
  final DateTime createdAt;
  final DateTime? dueAt; // Có thể null
  final String? assignee; // Có thể null

  Task({
    required this.id,
    required this.type,
    required this.status,
    required this.priority,
    required this.payload,
    required this.createdAt,
    this.dueAt,
    this.assignee,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      // API của bạn sẽ trả về _id là một String
      id: json['_id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      payload: Payload.fromJson(json['payload'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      // Kiểm tra giá trị null trước khi parse
      dueAt: json['due_at'] == null ? null : DateTime.parse(json['due_at'] as String),
      assignee: json['assignee'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'priority': priority,
      'payload': payload.toJson(),
      'created_at': createdAt.toIso8601String(),
      'due_at': dueAt?.toIso8601String(),
      'assignee': assignee,
    };
  }
}