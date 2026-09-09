import 'package:flutter/material.dart';

import 'story_state_widget.dart';
import 'story_empty_card.dart';

/// Renders the canonical four-state UI: loading → error → empty → data.
///
/// Consumers read state from a Controller / FutureProvider / AsyncSnapshot
/// and pass the four flags (`isLoading`, `error`, `isEmpty`, `data`) into
/// this scaffold. When non-loading and no error/empty condition holds,
/// the `dataBuilder` is invoked to render the actual content.
///
/// Behaviour precedence: `isLoading` → `error` (if non-null) → `isEmpty`
/// → `dataBuilder`.
///
/// Example:
/// ```dart
/// PageDataScaffold<List<Drama>>(
///   isLoading: state.isLoading,
///   errorMessage: state.lastError == null
///       ? null
///       : context.l10nError(state.lastError!),
///   isEmpty: !state.isLoading && state.dramas.isEmpty,
///   data: state.dramas,
///   dataBuilder: (_, dramas) => DramaListView(dramas),
///   onRetry: controller.refresh,
/// );
/// ```
typedef PageDataBuilder<T> = Widget Function(BuildContext context, T data);

class PageDataScaffold<T> extends StatelessWidget {
  const PageDataScaffold({
    super.key,
    required this.isLoading,
    required this.data,
    required this.dataBuilder,
    this.errorMessage,
    this.isEmpty = false,
    this.loadingMessage,
    this.emptyMessage,
    this.emptyLabel,
    this.retryLabel,
    this.onRetry,
  });

  final bool isLoading;
  final T data;
  final PageDataBuilder<T> dataBuilder;

  /// Localized error message — pass `null` for the no-error case.
  /// Caller-level localization keeps this widget UI-only.
  final String? errorMessage;

  final bool isEmpty;
  final String? loadingMessage;
  final String? emptyMessage;
  final String? emptyLabel;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return StoryStateWidget.loading(message: loadingMessage);
    }
    if (errorMessage != null) {
      return StoryStateWidget.error(
        message: errorMessage,
        actionLabel: retryLabel,
        onAction: onRetry,
      );
    }
    if (isEmpty) {
      if (emptyLabel != null) {
        return Center(child: StoryEmptyCard(label: emptyLabel!));
      }
      return StoryStateWidget.empty(
        message: emptyMessage,
        actionLabel: retryLabel,
        onAction: onRetry,
      );
    }
    return dataBuilder(context, data);
  }
}
