class ChargeModel {
  final String? id;
  final String? shiftId;
  final String? tableId;
  final String? waiterId;
  final String? waiterName;
  final double amount;
  final double tipAmount;
  final String currency;
  final String status;
  final String userId;
  final String concept;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  const ChargeModel({
    this.id,
    this.shiftId,
    this.tableId,
    this.waiterId,
    this.waiterName,
    required this.amount,
    this.tipAmount = 0.0,
    this.currency = 'MXN',
    this.status = 'pending',
    required this.userId,
    required this.concept,
    required this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  DateTime get effectiveTimestamp => updatedAt ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toSupabaseJson() {
    final Map<String, dynamic> data = {
      'amount': amount,
      'tip_amount': tipAmount,
      'currency': currency,
      'status': status,
      'user_id': userId,
      'concept': concept.trim().isEmpty ? 'Consumo mostrador' : concept.trim(),
      'payment_method': paymentMethod,
    };
    if (waiterName != null && waiterName!.isNotEmpty) {
      data['waiter_name'] = waiterName;
    }
    if (shiftId != null && shiftId!.isNotEmpty) {
      data['shift_id'] = shiftId;
    }
    if (tableId != null && _uuidRegExp.hasMatch(tableId!)) {
      data['table_id'] = tableId;
    }
    if (waiterId != null && waiterId != userId && _uuidRegExp.hasMatch(waiterId!)) {
      data['waiter_id'] = waiterId;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toIso8601String();
    }
    return data;
  }

  Map<String, dynamic> toJson() => toSupabaseJson();

  factory ChargeModel.fromJson(Map<String, dynamic> json) {
    return ChargeModel(
      id: json['id']?.toString(),
      shiftId: json['shift_id']?.toString(),
      tableId: json['table_id']?.toString(),
      waiterId: json['waiter_id']?.toString(),
      waiterName: json['waiter_name']?.toString(),
      amount: (json['amount'] as num).toDouble(),
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MXN',
      status: json['status']?.toString() ?? 'pending',
      userId: json['user_id']?.toString() ?? '',
      concept: json['concept']?.toString() ?? 'Consumo mostrador',
      paymentMethod: json['payment_method']?.toString() ?? 'efectivo',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  ChargeModel copyWith({
    String? id,
    String? shiftId,
    String? tableId,
    String? waiterId,
    String? waiterName,
    double? amount,
    double? tipAmount,
    String? currency,
    String? status,
    String? userId,
    String? concept,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChargeModel(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      tableId: tableId ?? this.tableId,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      amount: amount ?? this.amount,
      tipAmount: tipAmount ?? this.tipAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      concept: concept ?? this.concept,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
