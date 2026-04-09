import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../core/utils/validators.dart';
import '../../providers/user_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Forgot Password'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSuccessState() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final userProvider = context.watch<UserProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_outlined, color: AppColors.primaryGreen, size: 38),
          ),
          const SizedBox(height: 20),
          Text('Reset Password', style: AppTypography.h2),
          const SizedBox(height: 8),
          Text('Enter your email address to receive a reset link', style: AppTypography.body.copyWith(color: AppColors.textMedium)),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 24),
          HunarmandButton(
            label: 'Send Reset Link',
            isLoading: userProvider.isLoading,
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              try {
                await userProvider.sendPasswordReset(_emailCtrl.text.trim());
                if (mounted) setState(() { _sent = true; });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📧', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Email Sent!', style: AppTypography.h2),
          const SizedBox(height: 10),
          Text('Check your inbox for the password reset link', style: AppTypography.body.copyWith(color: AppColors.textMedium), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          HunarmandButton(label: 'Back to Login', onPressed: () => context.go('/signup')),
        ],
      ),
    );
  }
}
