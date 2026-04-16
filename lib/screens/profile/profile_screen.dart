import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/app_provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final appProvider = context.watch<AppProvider>();
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
    }

    if (userProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📡', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text('Connection Error', style: AppTypography.h2),
                const SizedBox(height: 12),
                Text(
                  userProvider.error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => userProvider.signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/edit-profile'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile header
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(radius: 44, backgroundImage: NetworkImage(user.profileImageUrl)),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user.name, style: AppTypography.h2),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.purpleChip.withAlpha(20),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.purpleChip.withAlpha(80)),
                        ),
                        child: Text(
                          '${_buyerTypeEmoji(user.buyerType)} ${_buyerTypeLabel(user.buyerType)}',
                          style: AppTypography.small.copyWith(color: AppColors.purpleChip, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Activity stats
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatItem(emoji: '📦', label: 'Orders', value: '${user.totalOrders}', onTap: () {}),
                      _StatItem(emoji: '⭐', label: 'Reviews', value: '${user.totalReviews}', onTap: () {}),
                      _StatItem(emoji: '❤️', label: 'Saved', value: '${user.savedProducts.length}', onTap: () => context.push('/saved-items')),
                      _StatItem(emoji: '🏪', label: 'Vendors', value: '${user.savedVendors.length}', onTap: () => context.push('/saved-items')),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Account Info
                _SettingsSection(
                  title: 'Account Info',
                  items: [
                    _SettingsTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone),
                    _SettingsTile(icon: Icons.email_outlined, label: 'Email', value: user.email.isEmpty ? 'Not set' : user.email),
                    _SettingsTile(icon: Icons.location_on_outlined, label: 'Location', value: '${user.city}, ${user.province}'),
                  ],
                ),

                const SizedBox(height: 8),

                // Addresses
                Container(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text('Saved Addresses', style: AppTypography.h3),
                      ),
                      ...user.addresses.map((addr) => ListTile(
                        leading: Icon(addr.label == 'Home' ? Icons.home_outlined : Icons.work_outline_rounded, color: AppColors.primaryGreen),
                        title: Text(addr.label, style: AppTypography.bodyMedium),
                        subtitle: Text(addr.address, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                        trailing: addr.isDefault
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(100)),
                                child: Text('Default', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                              )
                            : const Icon(Icons.edit_outlined, size: 18, color: AppColors.textLight),
                      )),
                      ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined, color: AppColors.primaryGreen),
                        title: Text('+ Add New Address', style: AppTypography.body.copyWith(color: AppColors.primaryGreen)),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Settings
                Container(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Text('Settings', style: AppTypography.h3),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined, color: AppColors.textMedium),
                        title: Text('Notifications', style: AppTypography.body),
                        value: user.notifications,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: (_) => userProvider.toggleNotifications(),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.textMedium),
                        title: Text('Dark Mode', style: AppTypography.body),
                        value: appProvider.isDarkMode,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: (_) => appProvider.toggleTheme(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.language_outlined, color: AppColors.textMedium),
                        title: Text('Language', style: AppTypography.body),
                        trailing: Text(appProvider.isUrdu ? 'اردو' : 'English', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
                        onTap: () => context.push('/language'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Support
                _SettingsSection(
                  title: 'Support & Legal',
                  items: [
                    _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () {}),
                    _SettingsTile(icon: Icons.headset_mic_outlined, label: 'Contact Support', onTap: () {}),
                    _SettingsTile(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () {}),
                    _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
                  ],
                ),

                const SizedBox(height: 8),

                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('Change Password', style: AppTypography.body.copyWith(color: AppColors.primaryGreen)),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _showLogoutDialog(context),
                          child: Text('Logout', style: AppTypography.body.copyWith(color: AppColors.statusCancelled)),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('Delete Account', style: AppTypography.body.copyWith(color: AppColors.textLight)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); context.go('/'); },
            child: const Text('Logout', style: TextStyle(color: AppColors.statusCancelled)),
          ),
        ],
      ),
    );
  }

  String _buyerTypeLabel(String type) {
    switch (type) {
      case 'business': return 'Small Business';
      case 'bulk': return 'Bulk/Export Buyer';
      default: return 'Individual Buyer';
    }
  }

  String _buyerTypeEmoji(String type) {
    switch (type) {
      case 'business': return '🏪';
      case 'bulk': return '🚢';
      default: return '👤';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String emoji, label, value;
  final VoidCallback onTap;
  const _StatItem({required this.emoji, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.h3.copyWith(color: AppColors.primaryGreen)),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: AppTypography.h3),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMedium, size: 22),
      title: Text(label, style: AppTypography.body),
      subtitle: value != null ? Text(value!, style: AppTypography.small.copyWith(color: AppColors.textMedium)) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight) : null,
      onTap: onTap,
    );
  }
}
