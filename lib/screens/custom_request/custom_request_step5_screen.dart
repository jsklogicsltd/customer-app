import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../widgets/custom_request/custom_request_shared_widgets.dart';

class CustomRequestStep5Screen extends StatelessWidget {
  const CustomRequestStep5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CustomRequestProvider>();
    final userP = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Review & Confirm'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          CustomRequestStepper(
            currentStep: 5,
            onStepTap: (step) {
              if (step == 1) { context.pop(); context.pop(); context.pop(); context.pop(); }
              else if (step == 2) { context.pop(); context.pop(); context.pop(); }
              else if (step == 3) { context.pop(); context.pop(); }
              else if (step == 4) { context.pop(); }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Product Summary'),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    items: [
                      _summaryItem('Category', p.step1Category, Icons.category_outlined),
                      _summaryItem('Style', p.step1SubCategory, Icons.style_outlined),
                      _summaryItem('Type', p.step1ProductType, Icons.inventory_2_outlined),
                      _summaryItem('Request Title', p.step1ProductName, Icons.edit_note_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Specifications'),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    items: [
                      _summaryItem('Material', p.step2Material, Icons.layers_outlined),
                      _summaryItem('Color', p.step2Color, Icons.palette_outlined),
                      _summaryItem('Quantity', p.step2Quantity.toString(), Icons.numbers_outlined),
                      if (p.step4HomeLength.isNotEmpty || p.step4HomeWidth.isNotEmpty) ...[
                        _summaryItem('Home Dimensions', '${p.step4HomeLength}L x ${p.step4HomeWidth}W', Icons.photo_size_select_small),
                      ] else ...[
                        _summaryItem('Sizes', p.step2Sizes.isEmpty ? 'N/A' : p.step2Sizes.join(', '), Icons.straighten_outlined),
                        if (p.step4CustomMeasurements.isNotEmpty)
                          _summaryItem('Detailed Size', p.step4CustomMeasurements.entries.map((e) => '${e.key}: ${e.value}"').join(', '), Icons.square_foot),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Budget & Timeline'),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    items: [
                      _summaryItem('Budget (PKR)', 'Rs. ${p.step3BudgetMin} - ${p.step3BudgetMax}', Icons.payments_outlined),
                      _summaryItem('Expected By', p.step3Deadline, Icons.timer_outlined),
                      _summaryItem('Delivery', p.step3DeliveryType.toUpperCase(), Icons.local_shipping_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (p.step1Description.isNotEmpty) ...[
                    _buildSectionHeader('Notes for Artisan'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        p.step1Description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (p.step1Images.isNotEmpty) ...[
                    _buildSectionHeader('Reference Photos'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.step1Images.length,
                        itemBuilder: (context, i) => Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(p.step1Images[i].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  HunarmandButton(
                    label: p.isSubmitting ? 'Submitting...' : 'Confirm & Send to Artisans',
                    onPressed: p.isSubmitting ? null : () async {
                      try {
                        final id = await p.submitRequest(customerName: userP.user?.name ?? 'Customer');
                        p.setLastSubmittedId(id);
                        if (context.mounted) context.go('/custom-request/submitted');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    type: ButtonType.gold,
                    isLoading: p.isSubmitting,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildSummaryCard({required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text('$label:', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
