import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/category_provider.dart';

import '../../widgets/custom_request/custom_request_shared_widgets.dart';

class CustomRequestStep1Screen extends StatelessWidget {
  const CustomRequestStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final hierarchy = catProvider.hierarchy;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Create Custom Request'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: hierarchy.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CustomRequestStepper(
                  currentStep: 1,
                  onStepTap: (step) {
                    // Handled by back button or forward flow, 
                    // but could jump back if needed.
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Category', style: AppTypography.h2),
                      const SizedBox(height: 4),
                      Text('Choose the main category for your request', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: hierarchy.length,
                      itemBuilder: (context, index) {
                        final cat = hierarchy[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: _CategoryCard(
                                name: cat['name'],
                                icon: cat['icon'],
                                onTap: () {
                                  final p = context.read<CustomRequestProvider>();
                                  p.step1Category = cat['name'];
                                  p.step1SubCategory = ''; 
                                  p.step1ProductType = ''; 
                                  context.push('/custom-request/step2');
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name, icon;
  final VoidCallback onTap;

  const _CategoryCard({required this.name, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withAlpha(10), shape: BoxShape.circle),
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
