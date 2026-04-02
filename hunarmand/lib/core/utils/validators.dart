String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return 'Phone number is required';
  if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value.replaceAll(' ', ''))) {
    return 'Enter a valid phone number';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return null; // optional
  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validateRequired(String? value, [String field = 'This field']) {
  if (value == null || value.trim().isEmpty) return '$field is required';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validatePositiveNumber(String? value, [String field = 'Value']) {
  if (value == null || value.isEmpty) return '$field is required';
  final n = int.tryParse(value);
  if (n == null || n <= 0) return 'Enter a valid positive number';
  return null;
}
