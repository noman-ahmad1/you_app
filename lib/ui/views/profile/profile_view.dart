import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/press_scale.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/shared/verify_email_nudge.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/premium/premium_helper.dart';
import 'profile_viewmodel.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ProfileViewModel viewModel,
    Widget? child,
  ) {
    final user = viewModel.currentUser;
    if (user == null) {
      return const Scaffold(
        body: CustomLottieLoader(fullScreen: true),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.background),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TopBar(
              leadingIconAsset: AppConstants.back,
              onLeadingPressed: () {
                Navigator.pop(context);
              },
              title: 'Profile',
              iconColor: AppColors.primaryVeryDark,
              trailingActions: [
                IconButton(
                  icon:
                      const Icon(Icons.edit, color: AppColors.primaryVeryDark),
                  onPressed: viewModel.navigateToEditProfile,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (viewModel.showVerifyEmailNudge)
                          VerifyEmailNudge(
                            onVerify: viewModel.openVerifyEmail,
                            onDismiss: viewModel.dismissVerifyEmailNudge,
                          ),
                        if (viewModel.completionPercentage < 1.0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background.withAlpha(70),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Profile Completeness',
                                      style: GoogleFonts.crimsonPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryVeryDark,
                                      ),
                                    ),
                                    Text(
                                      '${(viewModel.completionPercentage * 100).toInt()}%',
                                      style: GoogleFonts.crimsonPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: viewModel.completionPercentage,
                                    backgroundColor:
                                        AppColors.primaryLight.withAlpha(50),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.secondary),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Space.verticalSpaceTiny(context),
                        ],
                        // Profile Picture
                        Hero(
                          tag: 'profile_pic',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryLight, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(50),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.secondaryVeryLight,
                              backgroundImage: user.profilePictureUrl != null &&
                                      user.profilePictureUrl!.isNotEmpty
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : AssetImage(user.defaultAvatar)
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        Space.verticalSpaceTiny(context),

                        // Name
                        Text(
                          user.fullName,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        if (user.isPremium) ...[
                          Space.verticalSpaceVTiny(context),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.darkYellow.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AppConstants.premiumBadgeFill,
                                    width: 16,
                                    height: 16,
                                    color: AppColors.camel),
                                const SizedBox(width: 4),
                                Text(
                                  'YOU+',
                                  style: GoogleFonts.crimsonPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.camel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Space.verticalSpaceVTiny(context),

                        // Username / Role
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.username != null
                                ? '@${user.username} • ${viewModel.displayRole}'
                                : viewModel.displayRole,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        Space.verticalSpaceTiny(context),
                        if (!user.isPremium) ...[
                          const _PremiumUpsellCard(),
                          Space.verticalSpaceTiny(context),
                        ],

                        // Profile Details Container
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background.withAlpha(100),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _buildProfileItem(
                                iconAsset: AppConstants.email,
                                title: 'Email',
                                value: user.email,
                                iconColor: AppColors.secondary,
                              ),
                              const Divider(height: 32),
                              _buildProfileItem(
                                iconAsset: AppConstants.phone,
                                title: 'Phone',
                                value: user.phoneNumber ?? 'Not specified',
                                iconColor: AppColors.secondary,
                              ),
                              const Divider(height: 32),
                              _buildProfileItem(
                                iconAsset: AppConstants.gift,
                                title: 'Date of Birth',
                                value: viewModel.formattedDateOfBirth,
                                iconColor: AppColors.secondary,
                              ),
                              const Divider(height: 32),
                              _buildProfileItem(
                                iconAsset: AppConstants.person,
                                title: 'Gender',
                                value: user.gender ?? 'Not specified',
                                iconColor: AppColors.secondary,
                              ),
                              if (user.isVolunteer) ...[
                                const Divider(height: 32),
                                _buildProfileItem(
                                  iconAsset: AppConstants.done,
                                  title: 'Volunteer Status',
                                  value: user.status
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  valueColor: user.status == 'active'
                                      ? Colors.green
                                      : AppColors.primaryDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Always available while unverified — unlike the banner
                        // above, which the user can dismiss for 7 days and would
                        // otherwise leave them no route back to verification.
                        if (viewModel.needsEmailVerification) ...[
                          Space.verticalSpaceTiny(context),
                          CustomButton(
                            text: "Verify Email",
                            backgroundColor: AppColors.secondary,
                            icon: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: AppColors.background,
                              size: 18,
                            ),
                            onPressed: viewModel.openVerifyEmail,
                          ),
                        ],
                        Space.verticalSpaceTiny(context),
                        CustomButton(
                            text: "Edit",
                            onPressed: () {
                              viewModel.navigateToEditProfile();
                            }),
                        Space.verticalSpaceTiny(context),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.secondary,
                          title: Text(
                            'Share anonymous usage data',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                            ),
                          ),
                          subtitle: Text(
                            'Helps us improve the app. Your journal, mood, and chat content is never collected.',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 11.5,
                              color: AppColors.background.withAlpha(200),
                            ),
                          ),
                          value: viewModel.analyticsEnabled,
                          onChanged: viewModel.setAnalyticsEnabled,
                        ),
                        Space.verticalSpaceTiny(context),
                        viewModel.isBusy
                            ? CustomLottieLoader(
                                width: 50,
                                height: 50,
                                loaderWidth: 100,
                                loaderHeight: 100,
                              )
                            : CustomButton(
                                onPressed: viewModel.deleteAccount,
                                text: 'Delete Account',
                                textColor: AppColors.red,
                              ),
                        Space.verticalSpaceTiny(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    // required IconData icon,
    required String iconAsset,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Image.asset(iconAsset, width: 24, height: 24, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.crimsonPro(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.crimsonPro(
                  fontSize: 16,
                  color: valueColor ?? AppColors.primaryVeryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) => ProfileViewModel();
}

/// Tappable upsell shown on the profile for non-premium users → Premium screen.
class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => PremiumHelper.open(source: 'profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.secondaryLight],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withAlpha(60),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(AppConstants.premiumBadgeFill,
                width: 26, height: 26, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock YOU+',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Unlimited support & deeper insights',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 12.5,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
