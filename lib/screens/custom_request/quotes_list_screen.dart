import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/custom_request.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/status_chip.dart';
import 'package:go_router/go_router.dart';

class QuotesListScreen extends StatelessWidget {
  const QuotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login to view quotes')));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('My Quotes', style: AppTypography.h3),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customRequests')
            .where('customerId', isEqualTo: user.id)
            .where('status', isNotEqualTo: 'new')
            .orderBy('status')
            .orderBy('submittedDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📜', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No quotes yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              final request = CustomRequest.fromMap(data);

              return _QuoteCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final CustomRequest request;
  const _QuoteCard({required this.request});

  @override
  Widget build(BuildContext context) {
    // User requested "If status == 'vendor-selected' -> show final price with a green 'View Quote' button"
    // However, I'll also show the button for quote_received as that's when a quote is actually viewable.
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => context.push('/custom-requests/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${request.productType} / ${request.category}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Budget: ${formatPKR(request.budgetMin)} — ${formatPKR(request.budgetMax)}',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${formatDate(request.submittedDate)}',
                    style: AppTypography.small.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
              if (request.status == 'vendor-selected' && request.quote != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Final Quote', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                        Text(formatPKR(request.quote!.totalPrice), 
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/custom-requests/${request.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('View Quote', style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
