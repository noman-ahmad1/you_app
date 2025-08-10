import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_theme.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, model, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Hello, STACKED!',
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Space.verticalSpaceMedium(context),
                        ElevatedButton(
                          style: AppTheme.largeButton,
                          onPressed: model.incrementCounter,
                          child: Text(
                            model.counterLabel,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
      // Container(
      //   decoration: const BoxDecoration(
      //     image: DecorationImage(
      //       image: AssetImage('assets/images/background.jpg'),
      //       fit: BoxFit.cover,
      //     ),
      //   ),
      //   child: SafeArea(
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 25.0),
      //       child: Center(
      //         child: Column(
      //           mainAxisSize: MainAxisSize.max,
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             Column(
      //               children: [
      //                 const Text(
      //                   'Hello, STACKED!',
      //                   style: TextStyle(
      //                     fontSize: 35,
      //                     fontWeight: FontWeight.w900,
      //                   ),
      //                 ),
      //                 Space.verticalSpaceMedium(context),
      //                 ElevatedButton(
      //                   style: AppTheme.largeButton,
      //                   onPressed: viewModel.incrementCounter,
      //                   child: Text(
      //                     viewModel.counterLabel,
      //                     style: const TextStyle(color: Colors.white),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //             Row(
      //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //               children: [
      //                 ElevatedButton(
      //                   onPressed: viewModel.showDialog,
      //                   child: const Text(
      //                     'Show Dialog',
      //                     style: TextStyle(
      //                       color: Colors.white,
      //                     ),
      //                   ),
      //                 ),
      //                 ElevatedButton(
      //                   onPressed: viewModel.showBottomSheet,
      //                   child: const Text(
      //                     'Show Bottom Sheet',
      //                     style: TextStyle(
      //                       color: Colors.white,
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             )
      //           ],
      //         ),
      //       ),
      //     ),
      //   ),
      // ),