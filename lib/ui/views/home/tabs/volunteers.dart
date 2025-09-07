import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/views/home/volunteer_card.dart';

class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, viewModel, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final height = mediaQuery.size.height;
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppConstants.background),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  TopBar(
                    title: 'Volunteers',
                    imageAssetPath: AppConstants.back,
                    color: AppColors.secondary,
                    onMenuPressed: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Hello Noman',
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
                              ),
                              Text(
                                textAlign: TextAlign.center,
                                'Our volunteers are here to listen.',
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryVeryDark),
                              ),
                              Space.verticalSpaceTiny(context),
                              ListView.builder(
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 7.0),
                                      child: VolunteerCard(
                                        username: 'Volunteer Listener',
                                        avatarPath: AppConstants.avatar,
                                        rating: 4,
                                        categories: ['Anxiety', 'ADHD'],
                                        onMessageTap: () {},
                                      ),
                                    );
                                  },
                                  itemCount: 10,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics()),
                              Space.verticalSpaceSmall(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
