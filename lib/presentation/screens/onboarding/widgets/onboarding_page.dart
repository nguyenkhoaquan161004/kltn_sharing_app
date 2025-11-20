import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../onboarding_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.all(32),
            child: SvgPicture.asset(
              data.illustration,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.note12M.copyWith(
              color: Colors.white.withOpacity(0.75),
              // height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
