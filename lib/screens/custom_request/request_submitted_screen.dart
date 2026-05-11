import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class RequestSubmittedScreen extends StatefulWidget {
  const RequestSubmittedScreen({super.key});

  @override
  State<RequestSubmittedScreen> createState() => _RequestSubmittedScreenState();
}

class _RequestSubmittedScreenState extends State<RequestSubmittedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestId = context.read<CustomRequestProvider>().lastSubmittedId ?? 'REQ-2026-090';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('✅', style: TextStyle(fontSize: 60))),
                ),
              ),
              const SizedBox(height: 20),
              Text('Request Submitted!', style: AppTypography.h1.copyWith(color: AppColors.primaryGreen)),
              const SizedBox(height: 8),
              Text('Your request has been received by our team.', style: AppTypography.body),
              const SizedBox(height: 4),
              Text(requestId, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium)),
              const SizedBox(height: 24),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _InfoRow(emoji: '📋', text: 'We are reviewing your requirement'),
                    SizedBox(height: 12),
                    _InfoRow(emoji: '⏰', text: 'You will receive a price quote within 48 hours'),
                    SizedBox(height: 12),
                    _InfoRow(emoji: '🔔', text: 'We\'ll notify you as soon as your quote is ready'),
                  ],
                ),
              ),
              
              const Spacer(),
              HunarmandButton(
                label: 'Track Request Status',
                onPressed: () => context.go('/custom-requests/$requestId'),
              ),
              const SizedBox(height: 12),
              HunarmandButton(
                label: 'Back to Home',
                type: ButtonType.outlined,
                onPressed: () {
                  if (context.mounted) {
                    // Use post-frame callback to ensure the current screen's lifecycle 
                    // is stable before transitioning back to the shell
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) context.go('/home');
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji, text;
  const _InfoRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTypography.small.copyWith(color: AppColors.textDark)),
        ),
      ],
    );
  }
}
