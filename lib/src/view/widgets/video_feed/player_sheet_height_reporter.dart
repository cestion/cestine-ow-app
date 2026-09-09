import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Reports the child's laid-out height into [heightNotifier].
///
/// Used by comment / drama sheets so the feed collapses to the **measured**
/// sheet top instead of only [StoryConstants.playerOverlaySheetHeight].
class PlayerSheetHeightReporter extends SingleChildRenderObjectWidget {
  const PlayerSheetHeightReporter({
    super.key,
    required this.heightNotifier,
    required Widget super.child,
  });

  final ValueNotifier<double> heightNotifier;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetHeightReporter(heightNotifier);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderSheetHeightReporter).notifier = heightNotifier;
  }
}

class _RenderSheetHeightReporter extends RenderProxyBox {
  _RenderSheetHeightReporter(this._notifier);

  ValueNotifier<double> _notifier;
  ValueNotifier<double> get notifier => _notifier;
  set notifier(ValueNotifier<double> value) {
    if (identical(_notifier, value)) return;
    _notifier = value;
    _scheduleReport();
  }

  @override
  void performLayout() {
    super.performLayout();
    _scheduleReport();
  }

  void _scheduleReport() {
    final h = size.height;
    if (h <= 0) return;
    if ((notifier.value - h).abs() < 0.5) return;
    // Defer notifier write out of layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((notifier.value - h).abs() >= 0.5) {
        notifier.value = h;
      }
    });
  }
}
