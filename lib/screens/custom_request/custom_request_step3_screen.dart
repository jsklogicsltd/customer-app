import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/category_provider.dart';

import '../../widgets/custom_request/custom_request_shared_widgets.dart';

class CustomRequestStep3Screen extends StatelessWidget {
  const CustomRequestStep3Screen({super.key});

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

    final subCategoryData = subCategories.firstWhere(
      (sub) => sub['name'] == requestProvider.step1SubCategory,
      orElse: () => <String, dynamic>{},
    );

    final productTypesRaw = subCategoryData.isNotEmpty 
        ? subCategoryData['productTypes'] as List
        : [];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Product Type'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          CustomRequestStepper(
            currentStep: 3,
            onStepTap: (step) {
              if (step == 1) {
                context.pop();
                context.pop();
              } else if (step == 2) {
                context.pop();
              }
            },
          ),
          SelectionSummaryCard(
            category: requestProvider.step1Category,
            subCategory: requestProvider.step1SubCategory,
          ),
          Expanded(
            child: productTypesRaw.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text('No product types found', style: AppTypography.h3),
                        TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                      ],
                    ),
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: productTypesRaw.length,
                      itemBuilder: (context, index) {
                        final rawItem = productTypesRaw[index];
                        String name = '';
                        String icon = subCategoryData['icon'] ?? '📦';
                        
                        if (rawItem is Map) {
                          name = rawItem['name'] ?? '';
                          icon = rawItem['icon'] ?? icon;
                        } else {
                          name = rawItem.toString();
                        }

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _ProductTypeTile(
                                name: name,
                                icon: icon,
                                onTap: () {
                                  final p = context.read<CustomRequestProvider>();
                                  p.step1ProductType = name;
                                  context.push('/custom-request/step4');
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

class _ProductTypeTile extends StatelessWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;
  const _ProductTypeTile({required this.name, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
