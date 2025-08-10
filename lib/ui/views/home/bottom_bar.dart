import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:you_app/ui/common/app_colors.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomBar({
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
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(
          width: width * 0.9,
          height: height * 0.07,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(40),
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
                  margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(30),
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
                    assetPath: 'assets/icons/community.png',
                    label: 'Community',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _TabItem(
                    assetPath: 'assets/icons/home.png',
                    label: 'Home',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _TabItem(
                    assetPath: 'assets/icons/chat.png',
                    label: 'Chat',
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
  final String assetPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.assetPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Image.asset(
            assetPath,
            height: 24,
            width: 24,
            color: isSelected ? AppColors.secondary : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
