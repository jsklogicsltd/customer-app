import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _buyerType = 'individual';
  String _province = 'Federal';
  String _city = 'Islamabad';
  final _addressCtrl = TextEditingController();

  final _provinces = ['Punjab', 'Sindh', 'KPK', 'Balochistan', 'Federal', 'Azad Kashmir'];
  final _cities = {
    'Punjab': ['Lahore', 'Faisalabad', 'Multan', 'Rawalpindi', 'Gujranwala'],
    'Sindh': ['Karachi', 'Hyderabad', 'Sukkur'],
    'KPK': ['Peshawar', 'Swat', 'Abbottabad'],
    'Balochistan': ['Quetta', 'Gwadar'],
    'Federal': ['Islamabad'],
    'Azad Kashmir': ['Muzaffarabad', 'Mirpur'],
  };

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = _cities[_province] ?? ['Islamabad'];
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: Text('Step 1/1', style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Text('Almost there!', style: AppTypography.small),
              ],
            ),
            const SizedBox(height: 20),
            // Buyer Type
            Text('I am a:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _BuyerTypeCard(
              type: 'individual',
              emoji: '👤',
              title: 'Individual',
              subtitle: 'Personal use',
              selected: _buyerType == 'individual',
              onTap: () => setState(() => _buyerType = 'individual'),
            ),
            const SizedBox(height: 10),
            _BuyerTypeCard(
              type: 'business',
              emoji: '🏪',
              title: 'Small Business / Boutique',
              subtitle: 'Reseller or boutique owner',
              selected: _buyerType == 'business',
              onTap: () => setState(() => _buyerType = 'business'),
            ),
            const SizedBox(height: 10),
            _BuyerTypeCard(
              type: 'bulk',
              emoji: '🚢',
              title: 'Bulk / Export Buyer',
              subtitle: 'Wholesale or international buyer',
              selected: _buyerType == 'bulk',
              onTap: () => setState(() => _buyerType = 'bulk'),
            ),
            const SizedBox(height: 20),
            // Province
            Text('Province', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _province,
              items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) {
                setState(() {
                  _province = v!;
                  _city = _cities[v]!.first;
                });
              },
              decoration: const InputDecoration(filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 14),
            // City
            Text('City', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: cities.contains(_city) ? _city : cities.first,
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v!),
              decoration: const InputDecoration(filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 14),
            // Address
            Text('Delivery Address', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'House/Street/Block number...',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            HunarmandButton(
              label: 'Complete Setup',
              isLoading: userProvider.isLoading,
              onPressed: () async {
                try {
                  await userProvider.updateProfile(
                    buyerType: _buyerType,
                    province: _province,
                    city: _city,
                    profileSetupComplete: true,
                  );
                  
                  if (_addressCtrl.text.isNotEmpty) {
                    await userProvider.addAddress(UserAddress(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: 'Default',
                      address: _addressCtrl.text.trim(),
                      isDefault: true,
                    ));
                  }

                  if (context.mounted) {
                    context.go('/home');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerTypeCard extends StatelessWidget {
  final String type, emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _BuyerTypeCard({
    required this.type,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTypography.small),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
