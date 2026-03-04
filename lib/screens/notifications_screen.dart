import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final typeColors = {
      'warning': AppColors.chartAmber,
      'info': AppColors.primary,
      'success': AppColors.secondary,
    };
    final typeIcons = {
      'warning': Icons.warning_amber_rounded,
      'info': Icons.info_outline,
      'success': Icons.check_circle_outline,
    };

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => state.goBack(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                  child: Icon(Icons.arrow_back, size: 18, color: fgColor),
                ),
              ),
              const SizedBox(width: 12),
              Text('Notifications', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = state.notifications[i];
              final color = typeColors[n.type] ?? AppColors.primary;
              final icon = typeIcons[n.type] ?? Icons.info_outline;
              return GestureDetector(
                onTap: () => state.markNotificationRead(n.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: n.read ? cardColor : AppColors.primary.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: n.read ? borderColor : AppColors.primary.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(n.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor))),
                        if (!n.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 4),
                      Text(n.message, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                      const SizedBox(height: 4),
                      Text(n.time, style: GoogleFonts.inter(fontSize: 10, color: mutedColor)),
                    ])),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}
