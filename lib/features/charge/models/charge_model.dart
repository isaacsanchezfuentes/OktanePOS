class ChargeModel {
  final String? id;
  final String? shiftId;
  final double amount;
  final String currency;
  final String status;
  final String userId;
  final String concept;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChargeModel({
    this.id,
    this.shiftId,
    required this.amount,
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
      'currency': currency,
      'status': status,
      'user_id': userId,
      'concept': concept.trim().isEmpty ? 'Consumo mostrador' : concept.trim(),
      'payment_method': paymentMethod,
    };
    if (shiftId != null && shiftId!.isNotEmpty) {
      data['shift_id'] = shiftId;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toIso8601String();
    }
    return data;
  }

  factory ChargeModel.fromJson(Map<String, dynamic> json) {
    return ChargeModel(
      id: json['id']?.toString(),
      shiftId: json['shift_id']?.toString(),
      amount: (json['amount'] as num).toDouble(),
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
}
