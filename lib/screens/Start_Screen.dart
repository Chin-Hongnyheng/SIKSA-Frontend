import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';

import '../widgets/button.dart';
import '../widgets/logo.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 130),

          /// LOGO
          const Center(child: LogoApp()),

          /// PAGE VIEW
          Flexible(
            child: PageView(
              controller: _controller,
              children: [
                _page(
                  "assets/animations/Online.json",
                  "Learn Online",
                  "Access lessons anytime and anywhere.",
                ),
                _page(
                  "assets/animations/Welcome.json",
                  "Stay Organized",
                  "Manage your classes and assignments easily.",
                ),
                _page(
                  "assets/animations/Phone.json",
                  "Mobile Friendly",
                  "Your student portal right in your pocket.",
                ),
              ],
            ),
          ),

          /// DOT INDICATOR
          SmoothPageIndicator(
            controller: _controller,
            count: 3,
            effect: const WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              dotColor: Colors.grey,
              activeDotColor: Color(0xFF1E6B2D),
            ),
          ),

          const SizedBox(height: 70),

          /// BUTTON
          AppButton(
            text: "Get Started",
            onPressed: () {
              context.go('/auth');
            },
          ),

          const SizedBox(height: 30),

          /// TERMS TEXT
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text.rich(
              TextSpan(
                text: 'By clicking ',
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '"Get Started"',
                    style: TextStyle(
                      color: Color(0xFF1E6B2D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ', you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF1E6B2D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' and acknowledge our '),
                  TextSpan(
                    text: 'Privacy Policy.',
                    style: TextStyle(
                      color: Color(0xFF1E6B2D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _page(String asset, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 300, child: Lottie.asset(asset)),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
