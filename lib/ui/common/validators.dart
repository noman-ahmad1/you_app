/// Centralised form validators for the signup flows.
///
/// Each `*` method returns `null` when the value is valid, or a user-facing
/// error message string when it isn't — so callers can do:
/// `final err = Validators.email(x); if (err != null) showDialog(err);`
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  // At least 6 chars, with at least one letter and one digit.
  static final RegExp _password = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$');
  // Letters, spaces, hyphens, apostrophes and dots (e.g. "Mary-Jane O'Neil").
  static final RegExp _name = RegExp(r"^[A-Za-z][A-Za-z .'\-]*$");
  static final RegExp _username = RegExp(r'^[a-z0-9_]{3,20}$');

  static String? email(String value) {
    return _email.hasMatch(value.trim())
        ? null
        : 'Please enter a valid email address.';
  }

  static String? password(String value) {
    return _password.hasMatch(value)
        ? null
        : 'Password must be at least 6 characters and include both a letter and a number.';
  }

  /// Validates a person name field. [field] is used in the message, e.g. "First name".
  static String? personName(String value, String field) {
    final v = value.trim();
    if (v.isEmpty) return '$field is required.';
    if (v.length < 2) return '$field is too short.';
    if (!_name.hasMatch(v)) return '$field can only contain letters.';
    return null;
  }

  static String? username(String value) {
    return _username.hasMatch(value.trim().toLowerCase())
        ? null
        : 'Username must be 3–20 characters using only letters, numbers, or underscores.';
  }

  /// Validates a 4-digit graduation year within a sensible range.
  static String? graduationYear(String value) {
    final v = value.trim();
    final year = int.tryParse(v);
    final current = DateTime.now().year;
    if (year == null || v.length != 4 || year < 1950 || year > current + 8) {
      return 'Please enter a valid graduation year.';
    }
    return null;
  }

  /// Whole-years age for a given date of birth.
  static int ageFrom(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
