import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/category_provider.dart';

import '../../widgets/custom_request/custom_request_shared_widgets.dart';

class CustomRequestStep2Screen extends StatelessWidget {
  const CustomRequestStep2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final requestProvider = context.watch<CustomRequestProvider>();
    final hierarchy = catProvider.hierarchy;

    final categoryData = hierarchy.firstWhere(
      (cat) => cat['name'] == requestProvider.step1Category,
      orElse: () => <String, dynamic>{},
    );

    final subCategories = categoryData.isNotEmpty 
        ? List<Map<String, dynamic>>.from(categoryData['subCategories'] as List)
        : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Select Style'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          CustomRequestStepper(
            currentStep: 2,
            onStepTap: (step) {
              if (step == 1) context.pop();
            },
          ),
          SelectionSummaryCard(
            category: requestProvider.step1Category,
          ),
          Expanded(
            child: subCategories.isEmpty
                ? const Center(child: Text('No subcategories found'))
                : AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: subCategories.length,
                      itemBuilder: (context, index) {
                        final subCat = subCategories[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: _SubCategoryCard(
                                name: subCat['name'],
                                icon: subCat['icon'] ?? '📁',
                                onTap: () {
                                  final p = context.read<CustomRequestProvider>();
                                  p.step1SubCategory = subCat['name'];
                                  p.step1ProductType = ''; 
                                  context.push('/custom-request/step3');
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

class _SubCategoryCard extends StatelessWidget {
  final String name, icon;
  final VoidCallback onTap;

  const _SubCategoryCard({required this.name, required this.icon, required this.onTap});

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
