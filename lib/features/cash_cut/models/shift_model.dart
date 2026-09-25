class ShiftModel {
  final String? id;
  final int? shiftNumber;
  final String userId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double initialCash;
  final double totalSales;
  final double cashSales;
  final double cardSales;
  final double qrSales;
  final double drawerCounted;
  final double difference;
  final String status; // 'open' or 'closed'
  final bool isModified;
  final List<dynamic>? modificationHistory;
  final DateTime? createdAt;

  const ShiftModel({
    this.id,
    this.shiftNumber,
    required this.userId,
    required this.openedAt,
    this.closedAt,
    this.initialCash = 0.0,
    this.totalSales = 0.0,
    this.cashSales = 0.0,
    this.cardSales = 0.0,
    this.qrSales = 0.0,
    this.drawerCounted = 0.0,
    this.difference = 0.0,
    this.status = 'open',
    this.isModified = false,
    this.modificationHistory,
    this.createdAt,
  });

  Map<String, dynamic> toSupabaseInsertJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'opened_at': openedAt.toIso8601String(),
      'initial_cash': initialCash,
      'status': status,
    };
    if (id != null) data['id'] = id;
    return data;
  }

  Map<String, dynamic> toSupabaseCloseJson() {
    return {
      'closed_at': (closedAt ?? DateTime.now()).toIso8601String(),
      'total_sales': totalSales,
      'cash_sales': cashSales,
      'card_sales': cardSales,
      'qr_sales': qrSales,
      'drawer_counted': drawerCounted,
      'difference': difference,
      'status': 'closed',
    };
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString(),
      shiftNumber: json['shift_number'] != null ? (json['shift_number'] as num).toInt() : null,
      userId: json['user_id']?.toString() ?? '',
      openedAt: json['opened_at'] != null 
          ? DateTime.tryParse(json['opened_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closed_at'] != null ? DateTime.tryParse(json['closed_at'].toString()) : null,
      initialCash: (json['initial_cash'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      cardSales: (json['card_sales'] as num?)?.toDouble() ?? 0.0,
      qrSales: (json['qr_sales'] as num?)?.toDouble() ?? 0.0,
      drawerCounted: (json['drawer_counted'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'closed',
      isModified: json['is_modified'] == true,
      modificationHistory: json['modification_history'] is List ? json['modification_history'] as List : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
