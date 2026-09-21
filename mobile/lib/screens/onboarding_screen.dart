import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Travel with confidence',
      'description': 'Get real-time contextual safety intelligence and verified community risk indicators while travelling.',
      'icon': 'navigation',
    },
    {
      'title': 'Stay connected',
      'description': 'Temporarily share your live journey with people you trust. Sharing expires automatically.',
      'icon': 'share',
    },
    {
      'title': 'Help when you need it',
      'description': 'One-tap emergency SOS dispatches alerts to trusted contacts and reveals nearby police and medical help.',
      'icon': 'emergency',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.softLavender.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            index == 0
                                ? Icons.explore_rounded
                                : index == 1
                                    ? Icons.share_location_rounded
                                    : Icons.emergency_rounded,
                            size: 54,
                            color: AppColors.primaryViolet,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            slide['description']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primaryViolet : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
