import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/cached_image.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categoryProvider.allCategories.length,
              itemBuilder: (context, index) {
                final cat = categoryProvider.allCategories[index];
                final isExpanded = _expanded.contains(cat.id);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
            ),
            child: Column(
              children: [
                // Category header
                GestureDetector(
                  onTap: () {
                    context.push('/products', extra: {'categoryName': cat.name});
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(14),
                      bottom: isExpanded ? Radius.zero : const Radius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        AppCachedImage(url: cat.image, height: 100, width: double.infinity),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withAlpha(150), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 28)),
                              Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${cat.productCount} products', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expanded.remove(cat.id);
                                } else {
                                  _expanded.add(cat.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Subcategories
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cat.subCategories.map((sub) {
                        return GestureDetector(
                          onTap: () => context.push('/products', extra: {'categoryName': cat.name, 'subCategory': sub}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                            ),
                            child: Text(
                              sub,
                              style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
