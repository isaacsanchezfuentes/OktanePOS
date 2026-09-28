class CashCutSummaryModel {
  final double totalCollected;
  final double totalCash;
  final double totalCard;
  final double totalQr;
  final int totalTransactions;
  final int pendingTransactions;
  final double averageTicket;
  final String userId;
  final List<Map<String, dynamic>> waiterBreakdown;

  const CashCutSummaryModel({
    required this.totalCollected,
    required this.totalCash,
    required this.totalCard,
    required this.totalQr,
    required this.totalTransactions,
    required this.pendingTransactions,
    required this.averageTicket,
    required this.userId,
    this.waiterBreakdown = const [],
  });

  factory CashCutSummaryModel.fromCharges(List<dynamic> rawCharges, String userId) {
    double cash = 0.0;
    double card = 0.0;
    double qr = 0.0;
    int paidCount = 0;
    int pendingCount = 0;

    final Map<String, Map<String, dynamic>> breakdownMap = {};

    for (final item in rawCharges) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final method = (item['payment_method'] ?? '').toString().toLowerCase();
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final tipAmount = (item['tip_amount'] as num?)?.toDouble() ?? 0.0;
      final waiterName = item['waiter_name']?.toString() ?? 'Sin Mesero';
      final waiterId = item['waiter_id']?.toString() ?? 'sin_mesero';

      if (status == 'paid') {
        paidCount++;
        if (method == 'efectivo') {
          cash += amount;
        } else if (method == 'tarjeta') {
          card += amount;
        } else if (method == 'qr') {
          qr += amount;
        } else {
          cash += amount;
        }

        if (!breakdownMap.containsKey(waiterName)) {
          breakdownMap[waiterName] = {
            'waiter_id': waiterId,
            'waiter_name': waiterName,
            'total_sales': 0.0,
            'cash_tips': 0.0,
            'card_tips': 0.0,
          };
        }

        final entry = breakdownMap[waiterName]!;
        entry['total_sales'] = (entry['total_sales'] as double) + amount;
        if (method == 'efectivo') {
          entry['cash_tips'] = (entry['cash_tips'] as double) + tipAmount;
        } else {
          entry['card_tips'] = (entry['card_tips'] as double) + tipAmount;
        }
      } else if (status == 'pending') {
        pendingCount++;
      }
    }

    final total = cash + card + qr;
    final avg = paidCount > 0 ? total / paidCount : 0.0;

    return CashCutSummaryModel(
      totalCollected: total,
      totalCash: cash,
      totalCard: card,
      totalQr: qr,
      totalTransactions: paidCount,
      pendingTransactions: pendingCount,
      averageTicket: avg,
      userId: userId,
      waiterBreakdown: breakdownMap.values.toList(),
    );
  }
}
