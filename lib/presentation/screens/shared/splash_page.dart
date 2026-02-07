import 'package:flutter/material.dart';

import '../../widgets/app_background.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const AppBackground(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
