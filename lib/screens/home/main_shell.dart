import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/app_provider.dart';

import 'home_screen.dart';
import '../browse/categories_screen.dart';
import '../orders/my_orders_screen.dart';
import '../profile/profile_screen.dart';
import '../custom_request/custom_request_step1_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    CustomRequestStep1Screen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    if (index == 2) {
      // Custom request tab — navigate directly
      context.push('/custom-request/step1');
      return;
    }
    setState(() => _currentIndex = index);
    context.read<AppProvider>().setNavIndex(index);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          _screens[0],
          _screens[1],
          _screens[3],
          _screens[4],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(index: 0, icon: Icons.home_rounded, label: 'Home', current: _currentIndex, onTap: _onTap),
                _NavItem(index: 1, icon: Icons.grid_view_rounded, label: 'Browse', current: _currentIndex, onTap: _onTap),
                // Center Request button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, AppColors.goldLight],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.gold.withAlpha(100), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                        Text('Request', style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                _NavItemWithBadge(
                  index: 3,
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  current: _currentIndex,
                  onTap: _onTap,
                ),
                _NavItem(index: 4, icon: Icons.person_rounded, label: 'Profile', current: _currentIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index, current;
  final IconData icon;
  final String label;
  final Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryGreen.withAlpha(20) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                size: 22,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final int index, current;
  final IconData icon;
  final String label;
  final Function(int) onTap;

  const _NavItemWithBadge({
    required this.index,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryGreen.withAlpha(20) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                size: 22,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
