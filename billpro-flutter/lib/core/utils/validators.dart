class Validators {
  Validators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    if (!mobileRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must have at least 1 uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must have at least 1 number';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>\/?]').hasMatch(value)) {
      return 'Password must have at least 1 special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (value.trim().length > 100) return 'Name must be under 100 characters';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP must be numeric';
    return null;
  }
}
