import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';


class CustomRequestStep4Screen extends StatefulWidget {
  const CustomRequestStep4Screen({super.key});

  @override
  State<CustomRequestStep4Screen> createState() =>
      _CustomRequestStep4ScreenState();
}

class _CustomRequestStep4ScreenState extends State<CustomRequestStep4Screen> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final p = context.read<CustomRequestProvider>();
      final u = context.read<UserProvider>();
      final requestId = await p.submitRequest(customerName: u.user?.name ?? 'Customer');

      p.setLastSubmittedId(requestId);

      if (mounted) {
        context.go('/custom-request/submitted');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CustomRequestProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Review & Submit'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 4, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review Your Request', style: AppTypography.h2),
                  const SizedBox(height: 6),
                  Text(
                    'Step 4 of 4: Review your details and submit',
                    style: AppTypography.small
                        .copyWith(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 20),

                  // ── What Happens Next ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primaryGreen.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happens next?',
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 12),
                        const _NextStep(emoji: '📋', text: 'Our team reviews your request'),
                        const _NextStep(emoji: '🔍', text: 'We find the best matched vendor'),
                        const _NextStep(emoji: '💰', text: 'You receive a price quote from us'),
                        const _NextStep(emoji: '✅', text: 'You confirm to place the order'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Summary Card ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Summary',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        _SummaryRow(
                            label: 'Category',
                            value: p.step1Category),
                        if (p.step1SubCategory.isNotEmpty)
                          _SummaryRow(
                              label: 'Sub-Category',
                              value: p.step1SubCategory),
                        if (p.step1ProductType.isNotEmpty)
                          _SummaryRow(
                              label: 'Product Type',
                              value: p.step1ProductType),
                        _SummaryRow(
                            label: 'Quantity',
                            value: '${p.step2Quantity} pieces'),
                        if (p.step2Sizes.isNotEmpty)
                          _SummaryRow(
                              label: 'Sizes',
                              value: p.step2Sizes.join(', ')),
                        if (p.step2Color.isNotEmpty)
                          _SummaryRow(label: 'Color', value: p.step2Color),
                        if (p.step2Material.isNotEmpty)
                          _SummaryRow(
                              label: 'Material', value: p.step2Material),
                        if (p.step3BudgetMin > 0)
                          _SummaryRow(
                              label: 'Budget',
                              value:
                                  '${formatPKR(p.step3BudgetMin)} - ${formatPKR(p.step3BudgetMax)}'),
                        if (p.step3Deadline.isNotEmpty)
                          _SummaryRow(
                              label: 'Deadline', value: p.step3Deadline),
                        _SummaryRow(
                            label: 'Delivery',
                            value: p.step3DeliveryType == 'domestic'
                                ? '🇵🇰 Domestic'
                                : '🌍 International'),
                        _SummaryRow(
                            label: 'Packaging',
                            value: p.step3Packaging.isNotEmpty 
                                ? p.step3Packaging[0].toUpperCase() + p.step3Packaging.substring(1)
                                : 'Not specified'),
                        if (p.step1Description.isNotEmpty)
                          _SummaryRow(
                              label: 'Notes', value: p.step1Description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Reference Images ──────────────────────────────────
                  if (p.step1Images.isNotEmpty) ...[
                    Text('Reference Images',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.step1Images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(p.step1Images[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom Buttons ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => context.pop(),
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: HunarmandButton(
                    label: _isSubmitting
                        ? 'Submitting...'
                        : 'Submit Request →',
                    type: ButtonType.gold,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String emoji;
  final String text;

  const _NextStep({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.small.copyWith(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTypography.small
                    .copyWith(color: AppColors.textMedium)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.small
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step, total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of $total',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
