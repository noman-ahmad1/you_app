import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

class FilterBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FilterBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    final tabWidth = (width * 0.9) / 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width * 0.9,
          height: height * 0.07,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(10),
            border: Border.all(color: AppColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated sliding highlight
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _getAlignment(currentIndex),
                child: Container(
                  width: tabWidth,
                  margin:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVeryLight.withAlpha(70),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
              // Tab items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TabItem(
                    text: 'Work',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _TabItem(
                    text: 'All',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _TabItem(
                    text: 'Personal',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(int index) {
    switch (index) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight =
        MediaQuery.of(context).size.height * 0.06; // match BottomBar height
    final iconSize = barHeight * 0.6; // 60% of bar height
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.crimsonPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
            // color: isSelected ? AppColors.secondary : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
