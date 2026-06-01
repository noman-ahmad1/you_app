import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class VolunteerBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadNotificationsCount;

  const VolunteerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotificationsCount = 0,
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
            color: AppColors.secondaryVeryLight.withAlpha(102),
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
                    assetPath: AppConstants.notification,
                    label: 'Pending Chat',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                    unreadNotificationsCount: unreadNotificationsCount,
                  ),
                  _TabItem(
                    assetPath: AppConstants.chat,
                    label: 'Active Chat',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _TabItem(
                    assetPath: AppConstants.stat,
                    label: 'Dashboard',
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
  final int unreadNotificationsCount;

  const _TabItem({
    required this.assetPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.unreadNotificationsCount = 0,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                assetPath,
                height: iconSize,
                width: iconSize,
                color: isSelected ? AppColors.secondary : AppColors.secondary,
              ),
              if (assetPath == AppConstants.notification)
                Positioned(
                  right: -4,
                  top: -4,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: unreadNotificationsCount > 0 ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
