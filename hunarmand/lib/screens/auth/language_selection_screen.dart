import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text('🏺', style: TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Language',
                style: AppTypography.h2.copyWith(color: AppColors.textDark),
              ),
              Text(
                'زبان منتخب کریں',
                style: AppTypography.h3.copyWith(color: AppColors.textMedium, fontFamily: 'sans-serif'),
              ),
              const SizedBox(height: 48),
              // English
              _LanguageCard(
                flag: '🇬🇧',
                languageName: 'English',
                nativeName: 'English',
                onTap: () {
                  context.read<AppProvider>().setLanguage('en');
                  context.go('/onboarding');
                },
              ),
              const SizedBox(height: 16),
              // Urdu
              _LanguageCard(
                flag: '🇵🇰',
                languageName: 'اردو',
                nativeName: 'Urdu',
                onTap: () {
                  context.read<AppProvider>().setLanguage('ur');
                  context.go('/onboarding');
                },
              ),
              const Spacer(),
              HunarmandButton(
                label: 'Continue with English',
                onPressed: () {
                  context.read<AppProvider>().setLanguage('en');
                  context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String languageName;
  final String nativeName;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.languageName,
    required this.nativeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageName,
                  style: AppTypography.h3.copyWith(color: AppColors.textDark),
                ),
                Text(nativeName, style: AppTypography.small),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGreen, size: 18),
          ],
        ),
      ),
    );
  }
}
