import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  String _buyerType = 'individual';
  String _province = 'Federal';
  String _city = 'Islamabad';
  bool _isLoading = false;

  final _provinces = ['Punjab', 'Sindh', 'KPK', 'Balochistan', 'Federal', 'Azad Kashmir'];
  final _cities = {
    'Punjab': ['Lahore', 'Faisalabad', 'Multan', 'Rawalpindi'],
    'Sindh': ['Karachi', 'Hyderabad'],
    'KPK': ['Peshawar', 'Swat'],
    'Balochistan': ['Quetta'],
    'Federal': ['Islamabad'],
    'Azad Kashmir': ['Muzaffarabad'],
  };

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _buyerType = user?.buyerType ?? 'individual';
    _province = user?.province ?? 'Federal';
    _city = user?.city ?? 'Islamabad';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cities = _cities[_province] ?? ['Islamabad'];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 48, backgroundImage: NetworkImage(user.avatar)),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(onPressed: () {}, child: Text('Change Photo', style: AppTypography.small.copyWith(color: AppColors.primaryGreen))),
            ),
            const SizedBox(height: 20),

            // Full Name
            Text('Full Name', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),

            // Email
            Text('Email', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white, prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),

            // Province
            Text('Province', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _province,
              items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() { _province = v!; _city = _cities[v]!.first; }),
              decoration: const InputDecoration(filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 16),

            // City
            Text('City', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: cities.contains(_city) ? _city : cities.first,
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v!),
              decoration: const InputDecoration(filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 16),

            // Buyer type
            Text('Buyer Type', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _buyerType,
              items: const [
                DropdownMenuItem(value: 'individual', child: Text('👤 Individual')),
                DropdownMenuItem(value: 'business', child: Text('🏪 Small Business')),
                DropdownMenuItem(value: 'bulk', child: Text('🚢 Bulk/Export Buyer')),
              ],
              onChanged: (v) => setState(() => _buyerType = v!),
              decoration: const InputDecoration(filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 32),

            HunarmandButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 600));
                if (!context.mounted) return;
                
                final userProvider = context.read<UserProvider>();
                userProvider.updateProfile(
                  name: _nameCtrl.text,
                  email: _emailCtrl.text,
                  buyerType: _buyerType,
                  province: _province,
                  city: _city,
                );
                
                setState(() => _isLoading = false);
                
                if (!context.mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.primaryGreen),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
