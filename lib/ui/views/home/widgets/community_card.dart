import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class CommunityCard extends StatelessWidget {
  final String title;
  final String description;
  final String membersCount;
  final String postsToday;
  final String assetPath;
  final String? coverPhotoUrl;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const CommunityCard({
    super.key,
    required this.title,
    required this.description,
    required this.membersCount,
    required this.postsToday,
    required this.assetPath,
    this.coverPhotoUrl,
    this.isJoined = true,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon inside a colored circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: _getIconBackgroundColor(title),
              ),
              child: Center(
                child: coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          coverPhotoUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            assetPath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Image.asset(
                        assetPath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_alt,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '$membersCount members',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text(
                      //   '·',
                      //   style: TextStyle(
                      //       color: Colors.grey[600],
                      //       fontWeight: FontWeight.bold),
                      // ),
                      // const SizedBox(width: 8),
                      // Text(
                      //   '$postsToday posts today',
                      //   style: GoogleFonts.inter(
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w500,
                      //     color: Colors.grey[600],
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Action
            // const SizedBox(width: 5),
            if (!isJoined)
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Join',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Image.asset(
                AppConstants.next, // Use your right arrow icon asset
                color: Colors.grey[600],
                height: 32,
                width: 32,
              ),
          ],
        ),
      ),
    );
  }

  // Color _getIconBackgroundColor(String title) {
  //   final lowerTitle = title.toLowerCase();
  //   if (lowerTitle.contains('anxiety')) {
  //     return const Color(0xFFA5C4A3); // Soft green
  //   } else if (lowerTitle.contains('depression')) {
  //     return const Color(0xFF9CA3C8); // Soft purple/blue
  //   } else if (lowerTitle.contains('burnout')) {
  //     return const Color(0xFFEDAD98); // Soft orange
  //   }
  //   return const Color(0xFFF0F0F0); // Default grey
  // }
}
