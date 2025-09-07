import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/community_card.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, model, child) {
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
                    title: 'Communities',
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
                                'You\'re not alone here. Connect, share, and grow with others on similar journeys — safely and supportively.',
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryVeryDark),
                              ),
                              Space.verticalSpaceTiny(context),
                              GridView.builder(
                                  itemBuilder: (context, index) {
                                    return CommunityCard(
                                      title: 'Anxiety',
                                      assetPath: AppConstants.anxiety,
                                      onTap: () {},
                                    );
                                  },
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.9,
                                  ),
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
