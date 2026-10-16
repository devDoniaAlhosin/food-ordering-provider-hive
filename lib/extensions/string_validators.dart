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
}
