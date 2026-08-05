import 'package:flutter/material.dart';

/// Data model describing a single onboarding slide.
class OnboardingItem {
  const OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
