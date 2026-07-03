import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/shared/lottie_like_button.dart';

/// Reusable, theme-aligned building blocks for community post / reply cards.

/// An optimistic thread/reply the user just submitted, shown as a "Posting…"
/// card until the real doc arrives from the Firestore stream. [id] is a local
/// key used for precise dedup/timeout removal.
class PendingContent {
  final int id;
  final String content;
  const PendingContent({required this.id, required this.content});
}

/// Animated "Posting…" placeholder card, styled like a real community card but
/// visually in-flight (gentle shimmer + spinner). Reused for threads & replies.
class PendingCard extends StatefulWidget {
  final String authorName;
  final String content;
  const PendingCard({
    super.key,
    required this.authorName,
    required this.content,
  });

  @override
  State<PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<PendingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.authorName.isNotEmpty
        ? widget.authorName[0].toUpperCase()
        : '?';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Pulse the whole card subtly to signal it's in-flight.
        final opacity = 0.6 + 0.4 * _controller.value;
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(240),
              AppColors.secondaryVeryLight.withAlpha(70),
            ],
          ),
          border: Border.all(
              color: AppColors.secondary.withAlpha(45), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientAvatar(initial: initial, isMe: true, size: 42),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.authorName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                ),
                const YouChip(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.content,
              style: GoogleFonts.crimsonPro(
                fontSize: 15,
                color: AppColors.primaryVeryDark.withAlpha(220),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Posting…',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondary,
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

/// Gradient circular avatar showing the author's initial.
class GradientAvatar extends StatelessWidget {
  final String initial;
  final bool isMe;
  final double size;
  const GradientAvatar({
    super.key,
    required this.initial,
    this.isMe = false,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMe
              ? const [AppColors.secondary, AppColors.secondaryLight]
              : const [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: (isMe ? AppColors.secondary : AppColors.primaryDark)
                .withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        initial,
        style: GoogleFonts.crimsonPro(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Small "You" pill shown next to the current user's own name.
class YouChip extends StatelessWidget {
  const YouChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'You',
        style: GoogleFonts.crimsonPro(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

/// Subtle rounded stat chip (asset icon + count), e.g. reply count.
class StatChip extends StatelessWidget {
  final String iconAsset;
  final String label;
  const StatChip({super.key, required this.iconAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryVeryDark.withAlpha(15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            image: AssetImage(iconAsset),
            width: 18,
            color: AppColors.primaryVeryDark.withAlpha(160),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.crimsonPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryVeryDark.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

/// Like chip: the Lottie heart + count, tinted when liked.
class LikeChip extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLike;
  final int count;
  const LikeChip({
    super.key,
    required this.isLiked,
    required this.onLike,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 12, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isLiked
            ? AppColors.secondary.withAlpha(28)
            : AppColors.primaryVeryDark.withAlpha(15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LottieLikeButton(isLiked: isLiked, onTap: onLike, size: 28),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: GoogleFonts.crimsonPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isLiked
                  ? AppColors.secondary
                  : AppColors.primaryVeryDark.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}
