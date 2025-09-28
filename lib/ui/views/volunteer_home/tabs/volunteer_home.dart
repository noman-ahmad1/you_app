import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/user_card.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';

class VolunteerHome extends StatelessWidget {
  const VolunteerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return ViewModelBuilder<VolunteerHomeViewModel>.reactive(
      viewModelBuilder: () => VolunteerHomeViewModel(),
      builder: (context, viewModel, child) {
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
                    title: 'Home',
                    imageAssetPath: AppConstants.logo,
                    onMenuPressed: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome Noman',
                                  style: GoogleFonts.crimsonPro(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                // Space.verticalSpaceVTiny(context),
                                ListView.builder(
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 7.0),
                                        child: UserCard(
                                          username: "Anonymous User",
                                          lastMessage: "Hey are you there?",
                                          timeAgo: "15 min",
                                          avatarPath: AppConstants.avatar,
                                          category: "Stress",
                                          type: UserCardType.activeChat,
                                          onMessageTap: () =>
                                              print("Open Chat"),
                                        ),
                                      );
                                    },
                                    itemCount: 10,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics()),
                              ],
                            ),
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
