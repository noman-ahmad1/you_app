import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

class JournalEntryBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isPremium;

  const JournalEntryBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isPremium = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    final tabWidth = (width * 0.9) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width * 0.9,
          height: height * 0.07,
          decoration: BoxDecoration(
            color: AppColors.background.withAlpha(50),
            border: Border.all(color: AppColors.background, width: 2),
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
                    text: 'Text',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _TabItem(
                    text: 'Voice',
                    isSelected: currentIndex == 1,
                    locked: !isPremium,
                    onTap: () => onTap(1),
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
        return Alignment.centerRight;
      default:
        return Alignment.centerRight;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool locked;
  final VoidCallback onTap;

  const _TabItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.crimsonPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
              if (locked) ...[
                const SizedBox(width: 5),
                Icon(Icons.lock_outline,
                    size: 15, color: AppColors.secondary.withAlpha(200)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
