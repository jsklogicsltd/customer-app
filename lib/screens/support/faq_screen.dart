import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            context,
            'How do I place an order?',
            'You can browse our catalog in the "Browse" tab, or use the "Request" button to send a custom requirement for a personalized quote.',
          ),
          _buildFAQItem(
            context,
            'How can I track my project?',
            'Go to the "Orders" tab. Every active project now features a real-time progress bar that shows exactly what stage your order is at.',
          ),
          _buildFAQItem(
            context,
            'What is a "Split Order"?',
            'Large or complex projects can be split between multiple vendors to ensure faster delivery and better quality management.',
          ),
          _buildFAQItem(
            context,
            'How do I talk to the vendor or admin?',
            'On any order card, tap the "Support" button to open a direct chat thread with our administration and the assigned vendor.',
          ),
          _buildFAQItem(
            context,
            'Can I cancel an order?',
            'Orders can be cancelled at any time before the vendor confirms the order. Once production starts, please contact support for assistance.',
          ),
          _buildFAQItem(
            context,
            'How do quotes work?',
            'Once you send a request, vendors provide quotes. You can review, compare, and accept the one that best fits your needs.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTypography.body.copyWith(color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }
}
