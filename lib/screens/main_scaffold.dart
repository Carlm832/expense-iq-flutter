import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class MainScaffold extends StatelessWidget {
  final String currentScreen;
  const MainScaffold({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

<<<<<<< HEAD
    const tabs = ['dashboard', 'history', 'scan', 'analytics', 'profile'];
    final tabIndex = tabs.indexOf(currentScreen).clamp(0, tabs.length - 1);

=======
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397
    Widget body;
    switch (currentScreen) {
      case 'history':
        body = const HistoryScreen();
      case 'analytics':
        body = const AnalyticsScreen();
      case 'profile':
        body = const ProfileScreen();
      case 'scan':
        body = const ScanScreen();
      default:
        body = const DashboardScreen();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
<<<<<<< HEAD
                _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', isActive: currentScreen == 'dashboard', onTap: () => state.setCurrentScreen('dashboard')),
                _NavItem(icon: Icons.history, activeIcon: Icons.history, label: 'History', isActive: currentScreen == 'history', onTap: () => state.setCurrentScreen('history')),
                _ScanNavItem(isActive: currentScreen == 'scan' || currentScreen == 'ocr', onTap: () => state.setCurrentScreen('scan')),
                _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics', isActive: currentScreen == 'analytics', onTap: () => state.setCurrentScreen('analytics')),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', isActive: currentScreen == 'profile', onTap: () => state.setCurrentScreen('profile')),
=======
                _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Home',
                    isActive: currentScreen == 'dashboard',
                    onTap: () => state.setCurrentScreen('dashboard')),
                _NavItem(
                    icon: Icons.history,
                    activeIcon: Icons.history,
                    label: 'History',
                    isActive: currentScreen == 'history',
                    onTap: () => state.setCurrentScreen('history')),
                _ScanNavItem(
                    isActive: currentScreen == 'scan' || currentScreen == 'ocr',
                    onTap: () => state.setCurrentScreen('scan')),
                _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Analytics',
                    isActive: currentScreen == 'analytics',
                    onTap: () => state.setCurrentScreen('analytics')),
                _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: currentScreen == 'profile',
                    onTap: () => state.setCurrentScreen('profile')),
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

<<<<<<< HEAD
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.isActive, required this.onTap});
=======
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.isActive,
      required this.onTap});
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
<<<<<<< HEAD
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
=======
    const activeColor = AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
<<<<<<< HEAD
            Icon(isActive ? activeIcon : icon, color: isActive ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isActive ? activeColor : inactiveColor)),
=======
            Icon(isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor)),
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397
          ],
        ),
      ),
    );
  }
}

class _ScanNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ScanNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
<<<<<<< HEAD
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.document_scanner, color: Colors.white, size: 22),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Text('Scan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isActive ? AppColors.primary : AppColors.mutedForeground)),
            ),
=======
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Icon(Icons.document_scanner,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            Text('Scan',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.mutedForeground)),
>>>>>>> 69db2b89082359f2961352849b07446b8e5da397
          ],
        ),
      ),
    );
  }
}
