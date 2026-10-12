import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/utils/responsive_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Learn Skills",
      "description": "Discover people around you willing to teach valuable skills.",
      "icon": Icons.school_rounded,
    },
    {
      "title": "Share Your Knowledge",
      "description": "Teach others and earn credits by sharing your skills.",
      "icon": Icons.share_rounded,
    },
    {
      "title": "Exchange & Grow",
      "description": "Connect, learn, and build your local community.",
      "icon": Icons.groups_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeIn,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onSkip() {
    _pageController.animateToPage(
      _onboardingData.length - 1,
      duration: AppConstants.animationNormal,
      curve: Curves.easeIn,
    );
  }

  void _onGetStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top action area (Skip)
            _buildSkipButton(isLastPage),

            // PageView for content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(
                    _onboardingData[index]['title'],
                    _onboardingData[index]['description'],
                    _onboardingData[index]['icon'],
                  );
                },
              ),
            ),

            // Bottom Area (Indicators & Buttons)
            _buildBottomArea(isLastPage),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: isLastPage ? 0.0 : 1.0,
            duration: AppConstants.animationQuick,
            child: TextButton(
              onPressed: isLastPage ? null : _onSkip,
              child: Text(
                'Skip',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          isLastPage
              ? CustomButton(
                  text: 'Get Started',
                  onPressed: _onGetStarted,
                )
              : Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Next',
                        type: ButtonType.primary,
                        onPressed: _onNext,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPageContent(String title, String description, IconData icon) {
    final bool isTablet = ResponsiveUtils.isTablet(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 650;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXL,
                  vertical: AppConstants.paddingL,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'onboarding_icon_$title',
                      child: Container(
                        padding: EdgeInsets.all(
                          isSmallScreen ? 24 : (isTablet ? 48 : 32),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: isSmallScreen ? 80 : (isTablet ? 160 : 120),
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 32 : 60),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
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

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: AppConstants.animationNormal,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).primaryColor : AppColors.dividerLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
