import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final menu = [
      (
        Icons.credit_card,
        'Payment Methods',
        'Manage your cards',
        'payment-methods'
      ),
      (
        Icons.notifications_outlined,
        'Notifications',
        'Alerts & reminders',
        'notifications'
      ),
      (
        Icons.shield_outlined,
        'Privacy & Security',
        'Data protection',
        'privacy'
      ),
      (
        Icons.dark_mode_outlined,
        'Appearance',
        'Dark mode & themes',
        'appearance'
      ),
      (
        Icons.pie_chart_outline,
        'Budget Manager',
        'Set spending limits',
        'budget'
      ),
      (Icons.help_outline, 'Help & Support', 'Get assistance', 'help'),
      (Icons.settings_outlined, 'Settings', 'App preferences', 'settings'),
    ];

    final totalSaved =
        state.expenses.length > 10 ? (state.expenses.length * 5.9).floor() : 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          child: Column(children: [
            // Profile header card
            Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: state.profileImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(state.profileImage,
                              fit: BoxFit.cover))
                      : const Icon(Icons.person,
                          size: 32, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(state.userName,
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: fgColor)),
                      Text(state.userEmail,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: mutedColor)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.account_balance_wallet,
                            size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text('Premium Member',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondary)),
                      ]),
                    ])),
                GestureDetector(
                  onTap: () => state.setCurrentScreen('editProfile'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.settings_outlined,
                        size: 18, color: mutedColor),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Stats
            Row(children: [
              _StatCard(
                  value: '${state.expenses.length}',
                  label: 'Receipts',
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor),
              const SizedBox(width: 12),
              _StatCard(
                  value: '6',
                  label: 'Months',
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor),
              const SizedBox(width: 12),
              _StatCard(
                  value: context.read<AppState>().formatCurrency(totalSaved.toDouble()),
                  label: 'Saved',
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  valueColor: AppColors.secondary),
            ]),
            const SizedBox(height: 16),
            // Menu
            Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              child: Column(
                  children: menu.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(children: [
                  if (i > 0) Divider(height: 1, color: borderColor),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => state.setCurrentScreen(item.$4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(item.$1, size: 18, color: mutedColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(item.$2,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: fgColor)),
                              Text(item.$3,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: mutedColor)),
                            ])),
                        Icon(Icons.chevron_right, size: 18, color: mutedColor),
                      ]),
                    ),
                  ),
                ]);
              }).toList()),
            ),
            const SizedBox(height: 16),
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.logout,
                icon: const Icon(Icons.logout,
                    size: 18, color: AppColors.destructive),
                label: Text('Sign Out',
                    style: GoogleFonts.inter(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: AppColors.destructive.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('ExpenseIQ v1.0.0',
                style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color fgColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color? valueColor;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.fgColor,
      required this.mutedColor,
      required this.cardColor,
      required this.borderColor,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? fgColor)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
      ]),
    ));
  }
}
