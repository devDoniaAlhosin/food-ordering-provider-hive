import 'package:flutter/material.dart';

/// Shared [InputDecoration] styles used across app text fields.
extension AppInputDecoration on InputDecoration {
  /// Applies the app's outlined field look while keeping any existing values.
  InputDecoration asAppOutlined({
    Color? fillColor,
    double radius = 12,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return copyWith(
      filled: true,
      fillColor: fillColor,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: this.border ?? border,
      enabledBorder: enabledBorder ??
          border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFD7CCC8)),
          ),
      focusedBorder: focusedBorder ??
          border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFE65100), width: 2),
          ),
      errorBorder: errorBorder ??
          border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFB3261E)),
          ),
      focusedErrorBorder: focusedErrorBorder ??
          border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
          ),
    );
  }

  /// Search-field variant with a leading search icon.
  InputDecoration asAppSearch({
    String hintText = 'Search menu…',
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: suffixIcon,
    ).asAppOutlined();
  }

  /// Multiline notes / special-request field.
  InputDecoration asAppNotes({
    String labelText = 'Special instructions',
    String hintText = 'Optional notes for this item',
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: const Icon(Icons.notes_outlined),
      alignLabelWithHint: true,
    ).asAppOutlined();
  }

  /// Compact numeric quantity field.
  InputDecoration asAppQuantity() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ).asAppOutlined(radius: 8);
  }
}
