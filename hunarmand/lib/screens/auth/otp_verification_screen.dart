import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/common/hunarmand_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  const OTPVerificationScreen({super.key, required this.phone});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  void _resendOTP() {
    setState(() => _secondsLeft = 60);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!')),
    );
  }

  void _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/profile-setup');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verify Phone Number'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android_outlined, color: AppColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Code sent to',
              style: AppTypography.body.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 4),
            Text(
              widget.phone,
              style: AppTypography.h3.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Demo: Use any 4 digits (e.g. 1234)',
                style: AppTypography.small.copyWith(color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 32),
            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    style: AppTypography.h2,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 3) {
                        _focusNodes[i + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Resend
            _secondsLeft > 0
                ? Text(
                    'Resend OTP in ${_secondsLeft}s',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  )
                : TextButton(
                    onPressed: _resendOTP,
                    child: Text('Resend OTP', style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                  ),
            const Spacer(),
            HunarmandButton(label: 'Verify & Continue', onPressed: _verify, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
