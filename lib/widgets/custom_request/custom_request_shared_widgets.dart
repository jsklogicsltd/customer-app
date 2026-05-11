import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class CustomRequestStepper extends StatelessWidget {
  final int currentStep;
  final Function(int)? onStepTap;

  const CustomRequestStepper({
    super.key,
    required this.currentStep,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStep(1, 'Category', Icons.category_outlined),
              _buildConnector(1),
              _buildStep(2, 'Style', Icons.style_outlined),
              _buildConnector(2),
              _buildStep(3, 'Type', Icons.inventory_2_outlined),
              _buildConnector(3),
              _buildStep(4, 'Details', Icons.assignment_outlined),
              _buildConnector(4),
              _buildStep(5, 'Review', Icons.fact_check_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final bool isActive = step == currentStep;
    final bool isCompleted = step < currentStep;

    return Expanded(
      child: GestureDetector(
        onTap: isCompleted ? () => onStepTap?.call(step) : null,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.primaryGreen 
                    : (isCompleted ? AppColors.primaryGreen.withAlpha(30) : AppColors.bgLight),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primaryGreen : (isCompleted ? AppColors.primaryGreen : AppColors.divider),
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 20,
                color: isActive ? Colors.white : (isCompleted ? AppColors.primaryGreen : AppColors.textLight),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.small.copyWith(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primaryGreen : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(int fromStep) {
    final bool isCompleted = fromStep < currentStep;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppColors.primaryGreen : AppColors.divider,
    );
  }
}

class SelectionSummaryCard extends StatelessWidget {
  final String? category;
  final String? subCategory;
  final String? productType;

  const SelectionSummaryCard({
    super.key,
    this.category,
    this.subCategory,
    this.productType,
  });

  @override
  Widget build(BuildContext context) {
    if (category == null || category!.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withAlpha(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(category!),
                if (subCategory != null && subCategory!.isNotEmpty) ...[
                  _arrow(),
                  _chip(subCategory!),
                ],
                if (productType != null && productType!.isNotEmpty) ...[
                  _arrow(),
                  _chip(productType!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Text(
      text,
      style: AppTypography.small.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
        fontSize: 11,
      ),
    );
  }

  Widget _arrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, size: 14, color: AppColors.textLight),
    );
  }
}
