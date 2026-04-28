import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/custom_request_provider.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/hunarmand_button.dart';

class CustomRequestStatusScreen extends StatelessWidget {
  final String requestId;
  const CustomRequestStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CustomRequestProvider>().getById(requestId);

    if (request == null) {
      return const Scaffold(body: Center(child: Text('Request not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(request.productName.isNotEmpty ? request.productName : request.id),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Summary
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(request.id, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      const SizedBox(width: 10),
                      StatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (request.productName.isNotEmpty)
                    _SummaryItem(label: 'Name', value: request.productName),
                  _SummaryItem(label: 'Product', value: request.productType),
                  _SummaryItem(label: 'Quantity', value: '${request.quantity} units'),
                  _SummaryItem(label: 'Budget', value: '${formatPKR(request.budgetMin)} — ${formatPKR(request.budgetMax)}'),
                  _SummaryItem(label: 'Deadline', value: formatDate(request.deadline)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Timeline
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Timeline', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  ...request.timeline.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final isLast = i == request.timeline.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: step.completed ? AppColors.gold : AppColors.bgLight,
                                border: Border.all(color: step.completed || step.current ? AppColors.gold : AppColors.divider, width: 2),
                              ),
                              child: step.completed ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                            ),
                            if (!isLast) Container(width: 2, height: 36, color: step.completed ? AppColors.gold : AppColors.divider),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.step, style: AppTypography.small.copyWith(
                                  fontWeight: step.completed || step.current ? FontWeight.w600 : FontWeight.normal,
                                  color: step.completed || step.current ? AppColors.textDark : AppColors.textLight,
                                )),
                                if (step.date.isNotEmpty)
                                  Text(step.date, style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            
            // Single Unified Quote Section
            if (request.status == 'quote_received' && request.quote != null) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.gold.withAlpha(40), blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Custom Order Quote', style: AppTypography.h3.copyWith(color: AppColors.gold)),
                        const Text('🏷️', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${request.category} > ${request.subCategory} > ${request.productType}', style: AppTypography.body),
                    const SizedBox(height: 4),
                    Text('Quantity: ${request.quantity} units', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                    const Divider(height: 30),
                    Text('Total Price', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatPKR(request.quote!.totalPrice), style: AppTypography.h1.copyWith(color: AppColors.gold)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('"All charges included"', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.textMedium),
                        const SizedBox(width: 8),
                        Text('Production Time: ${request.quote!.productionDays} days', style: AppTypography.small),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textMedium),
                        const SizedBox(width: 8),
                        Text('Expected Delivery: ${request.quote!.expectedDelivery}', style: AppTypography.small),
                      ],
                    ),
                    if (request.quote!.teamNote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Note: ${request.quote!.teamNote}', style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    HunarmandButton(
                      label: 'ACCEPT & PLACE ORDER ✓',
                      type: ButtonType.gold,
                      onPressed: () => context.push('/custom-requests/$requestId/confirm'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMedium,
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        child: const Text('Decline / Request Revision'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: AppTypography.small.copyWith(color: AppColors.textMedium))),
        Expanded(child: Text(value, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
