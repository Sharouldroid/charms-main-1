import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Ink.image(
              image: const AssetImage('assets/images/logo/seatrulogo1.png'),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              // alignment: Alignment.center,
            ),
            Ink.image(
              image: const AssetImage('assets/images/logo/cmslogo.png'),
              width: 200,
              height: 100,
              // fit: BoxFit.cover,
              // alignment: Alignment.center,
            ),
            const CircularProgressIndicator(strokeWidth: 4.0),
            const SizedBox(height: 16),
            const Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
