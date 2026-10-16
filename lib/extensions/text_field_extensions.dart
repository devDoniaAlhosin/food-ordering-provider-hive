import 'package:flutter/material.dart';

import 'input_decoration_extensions.dart';

/// Factory-style helpers for consistently styled [TextField] widgets.
extension AppTextField on TextField {
  /// Outlined search field used on the food menu.
  static TextField search({
    Key? key,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    String hintText = 'Search menu…',
    bool enabled = true,
  }) {
    final hasText = controller != null && controller.text.isNotEmpty;
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration().asAppSearch(
        hintText: hintText,
        suffixIcon: hasText && onClear != null
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    );
  }

  /// Generic outlined [TextField] with shared app decoration.
  static TextField outlined({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ).asAppOutlined(),
    );
  }
}
