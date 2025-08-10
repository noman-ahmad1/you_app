import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';

class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({Key? key}) : super(key: key);

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
          child: Center(
            child: Text(
              'Volunteers Screen',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
  
}