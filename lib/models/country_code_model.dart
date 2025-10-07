// models/country_model.dart
class Country {
  final String name;
  final String dialCode; // This is the phone code (+93, +358, etc.)
  final String countryCode; // This is the 2-letter country code (AF, AX, etc.)
  final String flag;

  Country({
    required this.name,
    required this.dialCode,
    required this.countryCode,
    required this.flag,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] ?? '',
      dialCode: json['dial_code'] ?? '',
      countryCode: json['code'] ?? '',
      flag: _getFlagEmoji(json['code'] ?? ''),
    );
  }

  static String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🏳️';

    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;

    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  @override
  String toString() => '$flag $name ($dialCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}
