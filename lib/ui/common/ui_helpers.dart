import 'dart:math';
import 'package:flutter/material.dart';
import 'package:you_app/ui/common/app_colors.dart';

class Space {
  static double _baseunit(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.35;

  static double vtiny(BuildContext context) => _baseunit(context) * 0.025;
  static double tiny(BuildContext context) => _baseunit(context) * 0.05;
  static double small(BuildContext context) => _baseunit(context) * 0.2;
  static double medium(BuildContext context) => _baseunit(context) * 0.35;
  static double large(BuildContext context) => _baseunit(context) * 0.6;
  static double massive(BuildContext context) => _baseunit(context) * 0.8;

  static Widget horizontalSpaceVTiny(BuildContext context) =>
      SizedBox(width: vtiny(context));
  static Widget horizontalSpaceTiny(BuildContext context) =>
      SizedBox(width: tiny(context));
  static Widget horizontalSpaceSmall(BuildContext context) =>
      SizedBox(width: small(context));
  static Widget horizontalSpaceMedium(BuildContext context) =>
      SizedBox(width: medium(context));
  static Widget horizontalSpaceLarge(BuildContext context) =>
      SizedBox(width: large(context));

  static Widget verticalSpaceVTiny(BuildContext context) =>
      SizedBox(height: vtiny(context));
  static Widget verticalSpaceTiny(BuildContext context) =>
      SizedBox(height: tiny(context));
  static Widget verticalSpaceSmall(BuildContext context) =>
      SizedBox(height: small(context));
  static Widget verticalSpaceMedium(BuildContext context) =>
      SizedBox(height: medium(context));
  static Widget verticalSpaceLarge(BuildContext context) =>
      SizedBox(height: large(context));
  static Widget verticalSpaceMassive(BuildContext context) =>
      SizedBox(height: massive(context));
}

Widget spacedDivider(BuildContext context) {
  const dividerHeight = 1.0;
  final screenSize = MediaQuery.of(context).size;
  return Column(
    children: [
      SizedBox(height: screenSize.height * 0.025),
      Container(
        height: dividerHeight,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.white],
          ),
        ),
      ),
      SizedBox(height: screenSize.height * 0.015),
    ],
  );
}

Widget verticalSpace(double height) => SizedBox(height: height);

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

double screenHeightFraction(BuildContext context,
        {int dividedBy = 1, double offsetBy = 0, double max = 3000}) =>
    min((screenHeight(context) - offsetBy) / dividedBy, max);

double screenWidthFraction(BuildContext context,
        {int dividedBy = 1, double offsetBy = 0, double max = 3000}) =>
    min((screenWidth(context) - offsetBy) / dividedBy, max);

double halfScreenWidth(BuildContext context) =>
    screenWidthFraction(context, dividedBy: 2);

double thirdScreenWidth(BuildContext context) =>
    screenWidthFraction(context, dividedBy: 3);

double quarterScreenWidth(BuildContext context) =>
    screenWidthFraction(context, dividedBy: 4);

double getResponsiveHorizontalSpaceMedium(BuildContext context) =>
    screenWidthFraction(context, dividedBy: 10);
double getResponsiveSmallFontSize(BuildContext context) =>
    getResponsiveFontSize(context, fontSize: 14, max: 15);

double getResponsiveMediumFontSize(BuildContext context) =>
    getResponsiveFontSize(context, fontSize: 16, max: 17);

double getResponsiveLargeFontSize(BuildContext context) =>
    getResponsiveFontSize(context, fontSize: 21, max: 31);

double getResponsiveExtraLargeFontSize(BuildContext context) =>
    getResponsiveFontSize(context, fontSize: 25);

double getResponsiveMassiveFontSize(BuildContext context) =>
    getResponsiveFontSize(context, fontSize: 30);

double getResponsiveFontSize(BuildContext context,
    {double? fontSize, double? max}) {
  max ??= 100;

  var responsiveSize = min(
      screenWidthFraction(context, dividedBy: 10) * ((fontSize ?? 100) / 100),
      max);

  return responsiveSize;
}
