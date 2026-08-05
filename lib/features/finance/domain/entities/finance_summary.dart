/// Balance and category breakdown for the selected date range.
class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expense,
    required this.balance,
    this.byCategory = const [],
  });

  final double income;
  final double expense;
  final double balance;
  final List<CategoryTotal> byCategory;
}

class CategoryTotal {
  const CategoryTotal({required this.category, required this.total, required this.count});

  final String category;
  final double total;
  final int count;
}
