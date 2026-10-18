/// Shared string validators used by [TextFormField] extensions.
extension StringValidators on String? {
  /// Returns an error when [this] exceeds [maxLength]. Empty values are allowed.
  String? maxLengthValidator(int maxLength, {String fieldName = 'Field'}) {
    final text = this ?? '';
    if (text.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Requires a positive integer (quantity at least 1).
  String? positiveIntValidator({String fieldName = 'Quantity'}) {
    final text = (this ?? '').trim();
    if (text.isEmpty) return '$fieldName is required';
    final value = int.tryParse(text);
    if (value == null) return '$fieldName must be a number';
    if (value < 1) return '$fieldName must be at least 1';
    return null;
  }

  String? requiredValidator({String fieldName = 'Field'}) {
    final text = (this ?? '').trim();
    if (text.isEmpty) return '$fieldName is required';
    return null;
  }

  String? emailValidator() {
    final text = (this ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? passwordValidator({int minLength = 6}) {
    final text = this ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  String? phoneValidator({bool required = true}) {
    final text = (this ?? '').trim();
    if (text.isEmpty) {
      return required ? 'Phone is required' : null;
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Enter a valid phone number';
    return null;
  }
}
