import 'package:flutter/material.dart';

/// Utility class for keyboard and focus management.
///
/// Provides helpers to dismiss keyboard when tapping outside focused
/// text fields, preventing unnecessary unfocus-refocus cycles that
/// cause keyboard flicker and page jumps.
class KeyboardUtils {
  KeyboardUtils._();

  /// Dismiss keyboard when tapping outside the focused text field.
  ///
  /// Must not unfocus when the pointer lands on the already-focused field —
  /// otherwise the field blurs then immediately refocuses, keyboard
  /// viewInsets flicker, and the page jumps.
  ///
  /// Usage:
  /// ```dart
  /// Listener(
  ///   onPointerDown: KeyboardUtils.unfocusIfOutsideEditable,
  ///   child: ...
  /// )
  /// ```
  static void unfocusIfOutsideEditable(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    if (pointerHitsFocusedEditable(event, focus)) return;
    focus.unfocus();
  }

  /// Checks if the pointer event hits the currently focused editable widget.
  ///
  /// Returns `true` if the pointer is over the focused [TextField],
  /// [EditableText], or [InputDecorator], indicating that the keyboard
  /// should NOT be dismissed.
  ///
  /// This is useful when you want to implement custom focus management
  /// while preserving the standard keyboard behavior for the focused field.
  static bool pointerHitsFocusedEditable(
    PointerDownEvent event,
    FocusNode focus,
  ) {
    final focusedContext = focus.context;
    if (focusedContext == null) return false;

    Element? hitElement;
    void consider(Element element) {
      final widget = element.widget;
      if (widget is TextField ||
          widget is EditableText ||
          widget is InputDecorator) {
        hitElement = element;
      }
    }

    if (focusedContext is Element) {
      consider(focusedContext);
    }
    focusedContext.visitAncestorElements((element) {
      consider(element);
      // Prefer the outermost TextField box (includes padding/decoration).
      return element.widget is! TextField;
    });

    final renderObject = hitElement?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final local = renderObject.globalToLocal(event.position);
    return renderObject.size.contains(local);
  }

  /// Creates a callback for [Listener.onPointerDown] that unfocuses
  /// when tapping outside the focused editable.
  ///
  /// Convenience method for creating a reusable callback.
  ///
  /// Usage:
  /// ```dart
  /// Listener(
  ///   onPointerDown: KeyboardUtils.onPointerDownUnfocusOutside,
  ///   child: ...
  /// )
  /// ```
  static PointerDownEventListener get onPointerDownUnfocusOutside =>
      unfocusIfOutsideEditable;
}
