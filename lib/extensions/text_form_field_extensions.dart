import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'input_decoration_extensions.dart';
import 'string_validators.dart';

/// Factory-style helpers for consistently styled [TextFormField] widgets.
extension AppTextFormField on TextFormField {
  /// Optional special-instructions field with max-length validation.
  static TextFormField notes({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    int maxLength = 80,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: 2,
      maxLength: maxLength,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      validator: validator ??
          (value) => value.maxLengthValidator(
                maxLength,
                fieldName: 'Special instructions',
              ),
      decoration: InputDecoration().asAppNotes(),
    );
  }

  /// Compact quantity editor with positive-integer validation.
  static TextFormField quantity({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator ?? (value) => value.positiveIntValidator(),
      decoration: InputDecoration().asAppQuantity(),
    );
  }
}
