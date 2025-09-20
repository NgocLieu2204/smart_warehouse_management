class TransactionModel {
  final String id;
  final String sku;
  final String type;
  final int qty;
  final String wh;
  final DateTime at;
  final String? by;
  final String? note;

  TransactionModel({
    required this.id,
    required this.sku,
    required this.type,
    required this.qty,
    required this.wh,
    required this.at,
    this.by,
    this.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] is Map ? json['_id']['\$oid'] : json['_id'],
      sku: json['sku'],
      type: json['type'],
      qty: json['qty'],
      wh: json['wh'],
      at: json['at'] is Map
          ? DateTime.parse(json['at']['\$date'])
          : DateTime.parse(json['at']),
      by: json['by'],
      note: json['note'],
    );
  }
}
