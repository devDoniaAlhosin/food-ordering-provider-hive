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

  /// Email field for login / register.
  static TextFormField email({
    Key? key,
    TextEditingController? controller,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      textInputAction: textInputAction,
      validator: (value) => value.emailValidator(),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
      ).asAppOutlined(),
    );
  }

  /// Password field for login / register.
  static TextFormField password({
    Key? key,
    TextEditingController? controller,
    String labelText = 'Password',
    bool obscureText = true,
    VoidCallback? onToggleVisibility,
    TextInputAction textInputAction = TextInputAction.done,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator ?? (value) => value.passwordValidator(),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: onToggleVisibility == null
            ? null
            : IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
      ).asAppOutlined(),
    );
  }

  /// Full name field for register / checkout.
  static TextFormField fullName({
    Key? key,
    TextEditingController? controller,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      textCapitalization: TextCapitalization.words,
      textInputAction: textInputAction,
      validator: (value) => value.requiredValidator(fieldName: 'Full name'),
      decoration: InputDecoration(
        labelText: 'Full name',
        prefixIcon: const Icon(Icons.person_outline),
      ).asAppOutlined(),
    );
  }

  /// Phone field for checkout / profile.
  static TextFormField phone({
    Key? key,
    TextEditingController? controller,
    TextInputAction textInputAction = TextInputAction.next,
    bool required = true,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      validator: (value) => value.phoneValidator(required: required),
      decoration: InputDecoration(
        labelText: required ? 'Phone' : 'Phone (optional)',
        hintText: '01xxxxxxxxx',
        prefixIcon: const Icon(Icons.phone_outlined),
      ).asAppOutlined(),
    );
  }

  /// Delivery address field for checkout.
  static TextFormField address({
    Key? key,
    TextEditingController? controller,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      maxLines: 2,
      textInputAction: textInputAction,
      validator: (value) =>
          value.requiredValidator(fieldName: 'Delivery address'),
      decoration: InputDecoration(
        labelText: 'Delivery address',
        hintText: 'Street, building, floor...',
        prefixIcon: const Icon(Icons.location_on_outlined),
        alignLabelWithHint: true,
      ).asAppOutlined(),
    );
  }
}
