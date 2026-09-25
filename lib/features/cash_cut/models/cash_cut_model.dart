class CashCutSummaryModel {
  final double totalCollected;
  final double totalCash;
  final double totalCard;
  final double totalQr;
  final int totalTransactions;
  final int pendingTransactions;
  final double averageTicket;
  final String userId;

  const CashCutSummaryModel({
    required this.totalCollected,
    required this.totalCash,
    required this.totalCard,
    required this.totalQr,
    required this.totalTransactions,
    required this.pendingTransactions,
    required this.averageTicket,
    required this.userId,
  });

  factory CashCutSummaryModel.fromCharges(List<dynamic> rawCharges, String userId) {
    double cash = 0.0;
    double card = 0.0;
    double qr = 0.0;
    int paidCount = 0;
    int pendingCount = 0;

    for (final item in rawCharges) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final method = (item['payment_method'] ?? '').toString().toLowerCase();
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

      if (status == 'paid') {
        paidCount++;
        if (method == 'efectivo') {
          cash += amount;
        } else if (method == 'tarjeta') {
          card += amount;
        } else if (method == 'qr') {
          qr += amount;
        } else {
          cash += amount; // default fallback
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
    );
  }
}
