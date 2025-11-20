import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    // Delay 3 seconds and then navigate to onboarding screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          const _TriangleOverlay(
            alignment: Alignment.topRight,
            isTopRight: true,
            size: 220,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                Color.fromARGB(0, 52, 73, 94),
              ],
            ),
          ),
          const _TriangleOverlay(
            alignment: Alignment.bottomLeft,
            isTopRight: false,
            size: 180,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(0, 52, 73, 94),
                AppColors.primaryDark,
              ],
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/svgs/logo/icon.svg',
                      ),
                      SvgPicture.asset(
                        'assets/svgs/logo/name.svg',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleOverlay extends StatelessWidget {
  final Alignment alignment;
  final bool isTopRight;
  final double size;
  final Gradient gradient;

  const _TriangleOverlay({
    required this.alignment,
    required this.isTopRight,
    required this.size,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: ClipPath(
          clipper: _TriangleClipper(isTopRight: isTopRight),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(gradient: gradient),
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  final bool isTopRight;

  _TriangleClipper({required this.isTopRight});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isTopRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
