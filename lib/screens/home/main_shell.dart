import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void _onTap(int index) {
    if (index == 2) {
      // Custom request tab — navigate directly
      context.push('/custom-request/step1');
      return;
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    current: currentIndex,
                    onTap: _onTap),
                _NavItem(
                    index: 1,
                    icon: Icons.grid_view_rounded,
                    label: 'Browse',
                    current: currentIndex,
                    onTap: _onTap),
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
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.gold.withAlpha(100),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 28),
                        ),
                        Text('Request',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                _NavItemWithBadge(
                  index: 3,
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  current: currentIndex,
                  onTap: _onTap,
                ),
                _NavItem(
                    index: 4,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    current: currentIndex,
                    onTap: _onTap),
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
                color: isActive
                    ? AppColors.primaryGreen.withAlpha(20)
                    : Colors.transparent,
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
                color: isActive
                    ? AppColors.primaryGreen.withAlpha(20)
                    : Colors.transparent,
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
