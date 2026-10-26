import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/models/category.dart';
import 'package:flutter/material.dart';

/// Reloads a screen's data whenever the database changes.
mixin ReloadOnDataChange<T extends StatefulWidget> on State<T> {
  /// Loads (or reloads) the screen's data.
  Future<void> reload();

  int _loadGeneration = 0;

  /// Call at the start of [reload]; pass the result to [isLatestLoad] before
  /// applying results so a slow, older load never overwrites a newer one.
  int beginLoad() => ++_loadGeneration;

  /// Current generation, for incremental loads that must be discarded when
  /// a full reload starts meanwhile.
  int get currentLoad => _loadGeneration;

  bool isLatestLoad(int generation) => mounted && generation == _loadGeneration;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.changes.addListener(_onChanged);
    _run();
  }

  @override
  void dispose() {
    AppDatabase.instance.changes.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) _run();
  }

  void _run() {
    reload().catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      if (mounted) context.showSnack('Gagal memuat data.', error: true);
    });
  }
}

extension ContextFeedback on BuildContext {
  void showSnack(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    final scheme = Theme.of(this).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? scheme.error : null,
        ),
      );
  }

  /// Asks for confirmation; resolves to `true` only when confirmed.
  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Hapus',
    bool destructive = true,
  }) async {
    final scheme = Theme.of(this).colorScheme;
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: destructive ? scheme.error : null,
              foregroundColor: destructive ? scheme.onError : null,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Round icon badge for a transaction type.
class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.size = 44});

  final TransactionType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = type.isIncome ? scheme.income : scheme.expense;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.isIncome ? scheme.incomeContainer : scheme.expenseContainer,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        type.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}

/// Amount with sign and type colour, e.g. `+Rp 50.000`.
class AmountText extends StatelessWidget {
  const AmountText(this.amount, this.type, {super.key, this.style});

  final int amount;
  final TransactionType type;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '${type.isIncome ? '+' : '-'}${Money.format(amount)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ?? Theme.of(context).textTheme.titleSmall)?.copyWith(
        fontWeight: FontWeight.w700,
        color: type.isIncome ? scheme.income : scheme.expense,
      ),
    );
  }
}

/// Rounded white surface used for grouped content.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
