class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Disallow any spaces in the password
    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    // Minimum length check
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    // Remove leading/trailing spaces
    value = value.trim();

    // Check minimum length
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    // Regex: allows only letters (A–Z, a–z) and spaces
    final nameRegExp = RegExp(r'^[A-Za-z ]+$');

    if (!nameRegExp.hasMatch(value)) {
      return 'Name can contain only letters and spaces';
    }

    // Prevent names made of only spaces
    if (value.replaceAll(' ', '').isEmpty) {
      return 'Name cannot be only spaces';
    }

    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
