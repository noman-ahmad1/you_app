import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
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

    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(
          vertical:
              verticalPadding ?? screenHeight * 0.0177, // 2% of screen height
          horizontal:
              horizontalPadding ?? screenWidth * 0.358, // 40% of screen width
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
                    fontSize:
                        fontSize ?? screenWidth * 0.045, // 4.5% of screen width
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
