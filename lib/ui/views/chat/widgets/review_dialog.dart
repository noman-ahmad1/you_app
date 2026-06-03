import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

class ReviewDialog extends StatefulWidget {
  final String volunteerName;

  const ReviewDialog({Key? key, required this.volunteerName}) : super(key: key);

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Chat Completed",
              style: GoogleFonts.crimsonPro(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryVeryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "How was your session with ${widget.volunteerName}?",
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                fontSize: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            // Custom Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: GoogleFonts.crimsonPro(color: AppColors.primaryVeryDark),
              decoration: InputDecoration(
                hintText: "Leave a comment (optional)",
                hintStyle: GoogleFonts.crimsonPro(
                    color: AppColors.secondary.withAlpha(150)),
                filled: true,
                fillColor: AppColors.secondaryVeryLight.withAlpha(50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Returns null
                  },
                  child: Text(
                    "Skip",
                    style: GoogleFonts.crimsonPro(
                      color: AppColors.secondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    if (_rating == 0) {
                      // Optional: enforce rating
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a star rating.")),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'rating': _rating,
                      'comment': _commentController.text.trim(),
                    });
                  },
                  child: Text(
                    "Submit Review",
                    style: GoogleFonts.crimsonPro(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
