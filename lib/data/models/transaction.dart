import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/data/models/category.dart';

/// A single income/expense entry, joined with its category.
class TransactionEntry {
  const TransactionEntry({
    this.id,
    required this.nominal,
    required this.categoryId,
    required this.date,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  /// Builds an entry from a `transactions` row joined with `categories`
  /// columns aliased as `category_name`, `category_type` and
  /// `category_description`.
  factory TransactionEntry.fromJoinedMap(Map<String, Object?> map) {
    final categoryId = (map['category_id'] as num?)?.toInt() ?? 0;
    return TransactionEntry(
      id: (map['id'] as num?)?.toInt(),
      nominal: (map['nominal'] as num?)?.toInt() ?? 0,
      categoryId: categoryId,
      date: (map['date'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      category: map.containsKey('category_name')
          ? Category(
              id: categoryId,
              name: (map['category_name'] as String?) ?? '',
              description: map['category_description'] as String?,
              type: TransactionType.tryParse(map['category_type'] as String?) ??
                  TransactionType.expense,
            )
          : null,
    );
  }

  final int? id;
  final int nominal;
  final int categoryId;

  /// `yyyy-MM-dd`
  final String date;
  final String notes;
  final String? createdAt;
  final String? updatedAt;
  final Category? category;

  TransactionType get type => category?.type ?? TransactionType.expense;
  bool get isIncome => type.isIncome;
  DateTime get dateTime => Dates.fromDb(date) ?? Dates.today();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nominal': nominal,
        'category_id': categoryId,
        'date': date,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

/// Transactions that share the same date.
class TransactionGroup {
  const TransactionGroup(this.date, this.items);

  final DateTime date;
  final List<TransactionEntry> items;

  int get income =>
      items.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.nominal);
  int get expense =>
      items.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.nominal);
  int get net => income - expense;

  /// Groups an already date-sorted list, preserving order.
  static List<TransactionGroup> fromSorted(List<TransactionEntry> entries) {
    final groups = <TransactionGroup>[];
    for (final entry in entries) {
      final date = entry.dateTime;
      if (groups.isNotEmpty && groups.last.date == date) {
        groups.last.items.add(entry);
      } else {
        groups.add(TransactionGroup(date, [entry]));
      }
    }
    return groups;
  }
}

class Summary {
  const Summary({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  int get balance => income - expense;

  /// Share of income that has been spent, 0..1 (or above 1 when overspent).
  double get spendingRatio => income == 0 ? 0 : expense / income;
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.total,
    required this.share,
  });

  final int categoryId;
  final String name;
  final int total;

  /// Fraction of the period total, 0..1.
  final double share;
}

class TrendPoint {
  const TrendPoint(this.label, this.income, this.expense);

  final String label;
  final int income;
  final int expense;
}
