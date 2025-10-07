import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/country_code_model.dart';
import 'package:you_app/services/country_code_service.dart';
import 'package:you_app/ui/common/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final double? verticalPadding;
  final double? horizontalPadding;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? labelColor;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.labelText = '',
    this.hintText = '',
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.verticalPadding,
    this.horizontalPadding,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.contentPadding,
    this.fillColor = AppColors.background,
    this.labelColor = AppColors.secondaryLight,
    this.enabledBorderColor = AppColors.primaryDark,
    this.focusedBorderColor = AppColors.primaryVeryDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        fillColor: fillColor,
        filled: true,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding ?? screenHeight * 0.0177,
          horizontal: horizontalPadding ?? screenWidth * 0.07,
        ),
        labelStyle: TextStyle(color: labelColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(
            color: enabledBorderColor!,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(
            color: focusedBorderColor!,
            width: 2.0,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    Key? key,
    required this.controller,
    this.labelText = 'Phone Number',
    this.hintText = '300 123 4567',
    this.verticalPadding,
    this.horizontalPadding,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.fillColor = AppColors.background,
    this.labelColor = AppColors.secondaryLight,
    this.enabledBorderColor = AppColors.primaryDark,
    this.focusedBorderColor = AppColors.primaryVeryDark,
    this.initialDialCode = '+1',
    this.onCountryCodeChanged,
    this.showCountryFlag = true,
    this.showCountryName = true,
    this.autofocus = false,
  }) : super(key: key);

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final double? verticalPadding;
  final double? horizontalPadding;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Color fillColor;
  final Color labelColor;
  final Color enabledBorderColor;
  final Color focusedBorderColor;
  final String initialDialCode;
  final Function(String)? onCountryCodeChanged;
  final bool showCountryFlag;
  final bool showCountryName;
  final bool autofocus;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late String _selectedDialCode;
  late List<Country> _countries;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDialCode = widget.initialDialCode;
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    // WARNING: Replace with your actual CountryService locator call
    final countryService = locator<CountryService>();
    await countryService.loadCountries();
    setState(() {
      _countries = countryService.countries;
      _isLoading = false;

      // Set initial country
      final Country initialCountry =
          countryService.getCountryByDialCode(widget.initialDialCode);
      _selectedDialCode = initialCountry.dialCode;
    });
  }

  String get _fullPhoneNumber {
    // Only return the dial code if the input field is not empty, or if we want to include it always.
    // For signup/auth, it's safer to always include it.
    return '$_selectedDialCode${widget.controller.text}';
  }

  Country get _selectedCountry {
    final countryService = locator<CountryService>();
    return countryService.getCountryByDialCode(_selectedDialCode);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return _buildLoadingField(screenWidth, screenHeight);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.phone,
          autofocus: widget.autofocus,
          // Removed the extra horizontal padding from contentPadding to compensate
          // for the space taken by the prefixIcon.
          decoration: InputDecoration(
            fillColor: widget.fillColor,
            hintStyle: GoogleFonts.crimsonPro(
              color: AppColors.primaryVeryDark.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: _buildCountryCodeDropdown(),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              vertical: widget.verticalPadding ?? screenHeight * 0.0177,
              horizontal: widget.horizontalPadding ??
                  screenWidth * 0.03, // Reduced padding
            ),
            labelStyle: TextStyle(color: widget.labelColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(
                color: widget.enabledBorderColor,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(
                color: widget.focusedBorderColor,
                width: 2.0,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          validator: widget.validator,
          onChanged: (value) {
            widget.onChanged?.call(_fullPhoneNumber);
          },
          onFieldSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }

  Widget _buildLoadingField(double screenWidth, double screenHeight) {
    // ... (Loading field remains the same)
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        fillColor: widget.fillColor,
        filled: true,
        labelText: widget.labelText,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 8.0),
          child: SizedBox(
            width: 60,
            child: Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
              ),
            ),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: widget.verticalPadding ?? screenHeight * 0.0177,
          horizontal: widget.horizontalPadding ?? screenWidth * 0.07,
        ),
        labelStyle: TextStyle(color: widget.labelColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(
            color: widget.enabledBorderColor,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCodeDropdown() {
    final Country selectedCountry = _selectedCountry;

    return Padding(
      // Padding adjusted to shift the dropdown left, closer to the border
      padding: const EdgeInsets.only(left: 12.0, right: 0.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDialCode,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primaryVeryDark,
            size: 20,
          ),
          elevation: 16,
          style: const TextStyle(
            color: AppColors.primaryVeryDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          // 💡 FIX 1: Remove isExpanded: true so it only takes up necessary width
          // isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedDialCode = newValue;
              });
              widget.onCountryCodeChanged?.call(newValue);
              widget.onChanged?.call(_fullPhoneNumber);
            }
          },
          // 💡 FIX 2: Create a minimal display widget when not expanded
          selectedItemBuilder: (context) {
            return _countries.map((country) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Important for minimal width
                  children: [
                    if (widget.showCountryFlag) ...[
                      Text(
                        country.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      country.dialCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: _countries.map<DropdownMenuItem<String>>((Country country) {
            return DropdownMenuItem<String>(
              value: country.dialCode,
              // FIX 3: Removed BoxConstraints(minWidth: 100) to allow natural width
              child: Row(
                children: [
                  if (widget.showCountryFlag) ...[
                    Text(
                      country.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    country.dialCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CustomOtpField extends StatelessWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;
  final bool autoFocus;

  const CustomOtpField({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.controller,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PinCodeTextField(
      appContext: context,
      length: length,
      controller: controller,
      autoFocus: autoFocus,
      keyboardType: TextInputType.number,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(27),
        fieldHeight: screenHeight * 0.07,
        fieldWidth: screenWidth * 0.13,
        activeFillColor: AppColors.background,
        selectedFillColor: AppColors.background,
        inactiveFillColor: AppColors.background,
        activeColor: AppColors.primaryVeryDark,
        selectedColor: AppColors.primaryVeryDark,
        inactiveColor: AppColors.primaryDark,
        borderWidth: 2.0,
      ),
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: true,
      onCompleted: onCompleted,
      onChanged: (value) {},
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double? verticalPadding;
  final double? horizontalPadding;
  final double borderRadius;
  final double? fontSize;
  final FontWeight fontWeight;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.primaryVeryDark,
    this.textColor = AppColors.background,
    this.verticalPadding,
    this.horizontalPadding,
    this.borderRadius = 27,
    this.fontSize,
    this.fontWeight = FontWeight.w900,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.065, // 6% of screen height
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          padding: WidgetStateProperty.all(EdgeInsets.symmetric(
              // vertical:
              //     verticalPadding ?? screenHeight * 0.0177, // 2% of screen height
              // horizontal:
              //     horizontalPadding ?? screenWidth * 0.358, // 40% of screen width
              )),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          )),
          elevation: WidgetStateProperty.all(0),
        ),
        onPressed: onPressed,
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize ??
                          screenWidth * 0.045, // 4.5% of screen width
                      fontWeight: fontWeight,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize ?? screenWidth * 0.045,
                  fontWeight: fontWeight,
                ),
              ),
      ),
    );
  }
}

class CenteredDividerWithText extends StatelessWidget {
  final String text;
  final Color startColor;
  final Color endColor;
  final double spacing;
  final double thickness;
  final TextStyle? textStyle;

  const CenteredDividerWithText({
    super.key,
    required this.text,
    this.startColor = Colors.white,
    this.endColor = AppColors.primary,
    this.spacing = 8.0,
    this.thickness = 1.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            margin: EdgeInsets.only(right: spacing),
          ),
        ),
        Text(
          text,
          style: textStyle ??
              GoogleFonts.crimsonPro(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 14,
              ),
        ),
        Expanded(
          child: Container(
            height: thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor], // Reverse gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            margin: EdgeInsets.only(left: spacing),
          ),
        ),
      ],
    );
  }
}

class PaddedImageContainer extends StatelessWidget {
  final ImageProvider image;
  final double containerWidth;
  final double containerHeight;
  final Color backgroundColor;
  final double verticalPadding;
  final double horizontalPadding;
  final BoxFit fit;
  final double borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  const PaddedImageContainer({
    Key? key,
    required this.image,
    required this.containerWidth,
    required this.containerHeight,
    this.backgroundColor = AppColors.background,
    this.verticalPadding = 8.0,
    this.horizontalPadding = 20.0,
    this.fit = BoxFit.contain,
    this.borderRadius = 10,
    this.border,
    this.shadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadow,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        child: Center(
          child: Image(
            image: image,
            fit: fit,
            width: containerWidth - (horizontalPadding * 2),
            height: containerHeight - (verticalPadding * 2),
          ),
        ),
      ),
    );
  }
}
