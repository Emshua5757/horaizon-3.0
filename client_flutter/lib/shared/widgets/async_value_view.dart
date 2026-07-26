import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standardized Riverpod AsyncValue UI wrapper handling data, loading shimmers, and error cards
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Card(
        margin: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
          title: Text(
            'Error: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          trailing: onRetry != null
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRetry,
                  tooltip: 'Retry',
                )
              : null,
        ),
      ),
    );
  }
}
