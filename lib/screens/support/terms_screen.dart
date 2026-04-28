import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Karsaazi Terms of Service', style: AppTypography.h2),
            const SizedBox(height: 8),
            Text('Last updated: April 23, 2026', style: AppTypography.caption),
            const Divider(height: 32),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By using the Karsaazi platform, you agree to comply with our production standards and payment protocols. Karsaazi acts as a facilitator between customers and verified manufacturing vendors.',
            ),
            _buildSection(
              '2. Ordering & Quotations',
              'All quotations provided by vendors are valid for a period of 7 business days. Once a quote is accepted, it becomes a binding production agreement.',
            ),
            _buildSection(
              '3. Quality Assurance',
              'Karsaazi guarantees quality inspections at critical production milestones. If a product does not meet the specified requirements, the customer has the right to request rework before final delivery.',
            ),
            _buildSection(
              '4. Payment Terms',
              'Payments must be processed through the Karsaazi platform to ensure transaction security. Vendor payments are only released upon successful delivery and customer confirmation.',
            ),
            _buildSection(
              '5. Intellectual Property',
              'Any custom designs or technical drawings uploaded by the customer remain their property. Karsaazi and its vendors agree not to share these designs with third parties.',
            ),
            _buildSection(
              '6. Liability',
              'Karsaazi is not liable for delays caused by raw material shortages or natural disasters, but will actively coordinate with vendors to minimize impact on customer timelines.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Thank you for choosing Karsaazi.',
                style: AppTypography.small.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTypography.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
