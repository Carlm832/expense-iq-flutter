import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';
import '../theme.dart';
import '../services/translations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickProfilePhoto(BuildContext context, AppState state) async {
    final lang = state.language;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(Translations.t('camera', lang)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(Translations.t('gallery', lang)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(Translations.t('cancel', lang)),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      await state.setProfileImage(picked.path);
    }
  }

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

    final lang = state.language;
    final menu = [
      (
        Icons.notifications_outlined,
        Translations.t('notifications', lang),
        'Alerts & reminders',
        'notifications'
      ),
      (
        Icons.shield_outlined,
        Translations.t('privacy_security', lang),
        'Data protection',
        'privacy'
      ),
      (
        Icons.dark_mode_outlined,
        Translations.t('appearance', lang),
        'Dark mode & themes',
        'appearance'
      ),
      (
        Icons.pie_chart_outline,
        Translations.t('budget_manager', lang),
        'Set spending limits',
        'budget'
      ),
      (
        Icons.help_outline,
        Translations.t('help_support', lang),
        'Get assistance',
        'help'
      ),
      (
        Icons.settings_outlined,
        Translations.t('settings', lang),
        'App preferences',
        'settings'
      ),
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
                GestureDetector(
                  onTap: () => _pickProfilePhoto(context, state),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16)),
                        child: state.profileImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: state.profileImage.startsWith('http')
                                    ? Image.network(state.profileImage,
                                        fit: BoxFit.cover)
                                    : Image.file(File(state.profileImage),
                                        fit: BoxFit.cover))
                            : const Icon(Icons.person,
                                size: 32, color: AppColors.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
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
                    onTap: () => state.setCurrentScreen('edit_profile'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: mutedColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => state.setCurrentScreen('settings'),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            Row(children: [
              _StatCard(
                  value: '${state.expenses.length}',
                  label: Translations.t('receipts', lang),
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor),
              const SizedBox(width: 12),
              _StatCard(
                  value: '6',
                  label: Translations.t('months', lang),
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor),
              const SizedBox(width: 12),
              _StatCard(
                  value: state.formatCurrency(totalSaved.toDouble()),
                  label: Translations.t('saved', lang),
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
                label: Text(Translations.t('sign_out', lang),
                    style: GoogleFonts.inter(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('ExpenseIQ v1.0.0 @2026',
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
      child: Column(children: [
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor ?? fgColor)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: mutedColor)),
      ]),
    ));
  }
}
