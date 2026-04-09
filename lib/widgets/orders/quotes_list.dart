import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/quote.dart';
import 'quote_card.dart';

class QuotesList extends StatelessWidget {
  final List<QuoteModel> quotes;
  final bool isLoading;

  const QuotesList({
    super.key,
    required this.quotes,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined, // quote/document icon
                  size: 48, 
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No quotes yet',
                style: AppTypography.h3.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'When vendor sends a quote it will appear here',
                style: AppTypography.small.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return QuoteCard(quote: quotes[index]);
      },
    );
  }
}
