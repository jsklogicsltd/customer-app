import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../core/utils/validators.dart';
import '../../providers/user_provider.dart';
import '../../providers/app_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signUpKey = GlobalKey<FormState>();
  final _loginKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (!_signUpKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final appProvider = context.read<AppProvider>();

    try {
      await userProvider.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.isNotEmpty ? '+92 ${_phoneCtrl.text}' : null,
        language: appProvider.language,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to ${_emailCtrl.text}. Please verify before logging in.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.go('/profile-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
        );
      }
    }
  }

  void _handleLogin() async {
    if (!_loginKey.currentState!.validate()) return;
    
    final userProvider = context.read<UserProvider>();

    try {
      await userProvider.signIn(
        _loginEmailCtrl.text.trim(),
        _loginPasswordCtrl.text,
      );
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏺', style: TextStyle(fontSize: 28)),
                Text('KARSAAZI', style: AppTypography.h2.copyWith(color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 20),
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.textMedium,
                  labelStyle: AppTypography.bodyMedium,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Sign Up'), Tab(text: 'Login')],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildSignUpTab(), _buildLoginTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signUpKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              validator: (v) => validateRequired(v, 'Full Name'),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: validatePhone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixText: '+92 ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              validator: validatePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Terms
            Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) => setState(() => _termsAccepted = v!),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.small.copyWith(color: AppColors.textMedium),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            HunarmandButton(
              label: 'Sign Up',
              onPressed: _handleSignUp,
              isLoading: context.watch<UserProvider>().isLoading,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('Already have an account? Login',
                  style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _loginEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPasswordCtrl,
              obscureText: _obscurePassword,
              validator: validatePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text('Forgot Password?', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
              ),
            ),
            const SizedBox(height: 12),
            HunarmandButton(
              label: 'Login',
              onPressed: _handleLogin,
              isLoading: context.watch<UserProvider>().isLoading,
            ),
          ],
        ),
      ),
    );
  }

}
