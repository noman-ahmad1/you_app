// services/country_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:you_app/models/country_code_model.dart';

class CountryService {
  List<Country> _countries = [];

  Future<void> loadCountries() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/country_code.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _countries = jsonList
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort countries by name for better UX
      _countries.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error loading countries: $e');
      // Fallback to some common countries
      _countries = _getFallbackCountries();
    }
  }

  List<Country> get countries => _countries;

  Country getCountryByDialCode(String dialCode) {
    try {
      return _countries.firstWhere(
        (country) => country.dialCode == dialCode,
      );
    } catch (e) {
      // Fallback to US if not found
      return _countries.firstWhere(
        (country) => country.dialCode == '+1',
        orElse: () => _countries.first,
      );
    }
  }

  Country getCountryByCountryCode(String countryCode) {
    try {
      return _countries.firstWhere(
        (country) => country.countryCode == countryCode.toUpperCase(),
      );
    } catch (e) {
      // Fallback to US if not found
      return _countries.firstWhere(
        (country) => country.countryCode == 'US',
        orElse: () => _countries.first,
      );
    }
  }

  List<Country> _getFallbackCountries() {
    return [
      Country(
          name: 'United States',
          dialCode: '+1',
          countryCode: 'US',
          flag: '🇺🇸'),
      Country(
          name: 'United Kingdom',
          dialCode: '+44',
          countryCode: 'GB',
          flag: '🇬🇧'),
      Country(name: 'India', dialCode: '+91', countryCode: 'IN', flag: '🇮🇳'),
      Country(
          name: 'Australia', dialCode: '+61', countryCode: 'AU', flag: '🇦🇺'),
      Country(
          name: 'Germany', dialCode: '+49', countryCode: 'DE', flag: '🇩🇪'),
      Country(name: 'France', dialCode: '+33', countryCode: 'FR', flag: '🇫🇷'),
      Country(name: 'Japan', dialCode: '+81', countryCode: 'JP', flag: '🇯🇵'),
      Country(name: 'China', dialCode: '+86', countryCode: 'CN', flag: '🇨🇳'),
      Country(name: 'UAE', dialCode: '+971', countryCode: 'AE', flag: '🇦🇪'),
      Country(
          name: 'Singapore', dialCode: '+65', countryCode: 'SG', flag: '🇸🇬'),
    ];
  }
}
