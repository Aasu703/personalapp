import 'package:flutter/material.dart';

import '../../../core/constants/route_paths.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../data/models/onboarding_item.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_dots.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.lock_outline,
      title: 'Secure Authentication',
      description:
          'Your account is protected with industry-standard security so only you can access it.',
    ),
    OnboardingItem(
      icon: Icons.dashboard_customize_outlined,
      title: 'Everything in One Place',
      description:
          'Manage your profile, settings and preferences quickly from a single, simple dashboard.',
    ),
    OnboardingItem(
      icon: Icons.rocket_launch_outlined,
      title: 'Get Started in Seconds',
      description:
          'Create an account or sign in to begin. No complicated steps, just you and your app.',
    ),
  ];

  final PageController _controller = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _items.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed(RoutePaths.login);
  }

  void _next() {
    if (_isLastPage) {
      _goToLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(item: _items[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
            PageDots(count: _items.length, currentIndex: _currentPage),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppPrimaryButton(
                label: _isLastPage ? 'Get Started' : 'Next',
                icon: _isLastPage ? null : Icons.arrow_forward,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
