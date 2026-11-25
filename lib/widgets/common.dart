import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: c.withOpacity(0.5)), color: c.withOpacity(0.08)),
      child: Text(capitalize(status), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard(this.label, this.value, {super.key, this.note});
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              if (note != null) Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.icon = Icons.inbox_outlined});
  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 36, color: ink.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(message!, textAlign: TextAlign.center)),
          ]),
        ),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: vermilion.withOpacity(0.08), border: Border.all(color: vermilion.withOpacity(0.5))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: vermilion, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

/// "1 to 10 of 40" with previous and next buttons.
class PageFooter extends StatelessWidget {
  const PageFooter({super.key, required this.first, required this.last, required this.total, required this.page, required this.pages, required this.onPage});
  final int first, last, total, page, pages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(total == 0 ? 'No results' : '$first to $last of $total'),
        IconButton(tooltip: 'Previous page', icon: const Icon(Icons.chevron_left), onPressed: page > 1 ? () => onPage(page - 1) : null),
        Text('$page / $pages'),
        IconButton(tooltip: 'Next page', icon: const Icon(Icons.chevron_right), onPressed: page < pages ? () => onPage(page + 1) : null),
      ]);
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
