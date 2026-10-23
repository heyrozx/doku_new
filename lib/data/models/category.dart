enum TransactionType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  const TransactionType(this.value, this.label);

  /// Value stored in the database (`categories.type`).
  final String value;
  final String label;

  bool get isIncome => this == TransactionType.income;

  /// Parses a stored or imported value. Accepts the English database value
  /// as well as the Indonesian label (case-insensitive).
  static TransactionType? tryParse(String? raw) {
    final text = raw?.trim().toLowerCase();
    for (final type in values) {
      if (text == type.value || text == type.label.toLowerCase()) return type;
    }
    return null;
  }
}

class Category {
  const Category({
    this.id,
    required this.name,
    this.description,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int?,
        name: (map['name'] as String?) ?? '',
        description: map['description'] as String?,
        type: TransactionType.tryParse(map['type'] as String?) ??
            TransactionType.expense,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
      );

  final int? id;
  final String name;
  final String? description;
  final TransactionType type;
  final String? createdAt;
  final String? updatedAt;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'type': type.value,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
