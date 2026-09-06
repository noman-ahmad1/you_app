import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/shared/custom_lottie_loader.dart';
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_viewmodel.dart';

/// The bottom-of-form action row shared by the Text and Voice tabs: a
/// Work/Personal category dropdown next to the Save/Update button.
class JournalSaveRow extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  const JournalSaveRow({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SizedBox(
      width: width * 0.8,
      height: height * 0.065,
      child: Row(
        children: [
          _CategoryDropdown(viewModel: viewModel, width: width, height: height),
          SizedBox(width: width * 0.03),
          Expanded(child: _SaveButton(viewModel: viewModel)),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  final double width;
  final double height;
  const _CategoryDropdown(
      {required this.viewModel, required this.width, required this.height});

  static String _text(JournalLabel l) =>
      l == JournalLabel.work ? 'Work' : 'Personal';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width * 0.34,
          height: height * 0.065,
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
          child: PopupMenuButton<JournalLabel>(
            initialValue: viewModel.selectedLabel,
            onSelected: viewModel.setLabel,
            color: AppColors.background,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
            itemBuilder: (_) => [
              _menuItem(JournalLabel.personal),
              _menuItem(JournalLabel.work),
            ],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _text(viewModel.selectedLabel),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.secondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<JournalLabel> _menuItem(JournalLabel label) {
    return PopupMenuItem<JournalLabel>(
      value: label,
      child: Text(
        _text(label),
        style: GoogleFonts.crimsonPro(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  const _SaveButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: viewModel.isBusy ? null : viewModel.submit,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            padding: EdgeInsets.all(width * 0.007),
            height: height * 0.065,
            decoration: BoxDecoration(
              color: AppColors.primaryVeryDark,
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
            child: Center(
              child: viewModel.isBusy
                  ? const CustomLottieLoader(
                      width: 50,
                      height: 50,
                      loaderWidth: 200,
                      loaderHeight: 200,
                    )
                  : Text(
                      viewModel.isEditing ? 'Update' : 'Save',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
