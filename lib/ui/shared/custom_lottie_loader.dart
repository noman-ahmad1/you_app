import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class CustomLottieLoader extends StatelessWidget {
  final bool fullScreen;
  final double width;
  final double height;
  final double loaderWidth;
  final double loaderHeight;

  const CustomLottieLoader({
    Key? key,
    this.fullScreen = false,
    this.width = 300,
    this.height = 300,
    this.loaderWidth = 200,
    this.loaderHeight = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget loader = SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Lottie.asset(
          AppConstants.loading,
          decoder: customDecoder,
          width: loaderWidth,
          height: loaderHeight,
        ),
      ),
    );

    if (fullScreen) {
      return Container(
        color: AppColors.primary,
        child: Center(
          child: loader,
        ),
      );
    }

    return loader;
  }
}
