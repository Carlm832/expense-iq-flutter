import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

Widget _buildSimpleScreen(BuildContext context, String title, String subtitle, List<Widget> children) {
  final state = context.read<AppState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
  final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
  final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  final cardColor = isDark ? AppColors.darkCard : AppColors.card;
  final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
              if (subtitle.isNotEmpty) Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
            ]),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        )),
      ]),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Settings', 'App preferences', [
      Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        child: Column(children: [
          _SettingsTile(icon: Icons.language, label: 'Language', value: 'English', fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor),
          _SettingsTile(icon: Icons.currency_exchange, label: 'Currency', value: 'TRY (₺)', fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor),
          _SettingsTile(icon: Icons.notifications_outlined, label: 'Push Notifications', value: 'On', fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor),
          _SettingsTile(icon: Icons.backup_outlined, label: 'Backup Data', value: '', fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor),
          _SettingsTile(icon: Icons.delete_outline, label: 'Clear All Data', value: '', fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor, isDestructive: true),
        ]),
      ),
    ]);
  }
}

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Appearance', 'Dark mode & themes', [
      Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dark Mode', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: fgColor)),
            Text('Switch between light and dark theme', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          ])),
          Switch(value: state.isDarkMode, onChanged: (_) => state.toggleDarkMode(), activeColor: AppColors.primary),
        ]),
      ),
    ]);
  }
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final Map<String, TextEditingController> _ctrls = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    for (final b in state.budgets) {
      _ctrls.putIfAbsent(b.category, () => TextEditingController(text: b.limit.toStringAsFixed(0)));
    }

    return _buildSimpleScreen(context, 'Budget Manager', 'Set spending limits', [
      ...state.budgets.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: Text(b.category, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor))),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _ctrls[b.category],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₺',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (v) => state.setBudget(b.category, double.tryParse(v) ?? b.limit),
              ),
            ),
          ]),
        ),
      )),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            for (final entry in _ctrls.entries) {
              final limit = double.tryParse(entry.value.text) ?? 0;
              if (limit > 0) state.setBudget(entry.key, limit);
            }
            state.goBack();
          },
          child: const Text('Save Budgets'),
        ),
      ),
    ]);
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final faqs = [
      ('How do I add an expense?', 'Tap the + button on the dashboard or use the Add Expense form.'),
      ('How do I scan a receipt?', 'Use the Scan tab in the bottom navigation to scan receipts using your camera.'),
      ('How do I set a budget?', 'Go to Profile → Budget Manager to set spending limits per category.'),
      ('How do I export my data?', 'Go to History and tap the CSV button to export your transactions.'),
    ];
    return _buildSimpleScreen(context, 'Help & Support', 'Get assistance', [
      ...faqs.map((faq) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(faq.$1, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
            const SizedBox(height: 6),
            Text(faq.$2, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          ]),
        ),
      )),
    ]);
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Privacy & Security', 'Data protection', [
      Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Text(
          'Your data is stored locally on your device. We do not share your financial information with any third parties. All expense data is encrypted and protected.\n\nYou can delete all your data at any time from Settings → Clear All Data.',
          style: GoogleFonts.inter(fontSize: 13, color: mutedColor, height: 1.6),
        ),
      ),
    ]);
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Payment Methods', 'Manage your cards', [
      Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(Icons.credit_card, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No payment methods', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: fgColor)),
          Text('Add a card to track linked expenses', style: GoogleFonts.inter(fontSize: 12, color: mutedColor), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Payment Method'),
        ),
      ),
    ]);
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl = TextEditingController(text: state.userName);
    _emailCtrl = TextEditingController(text: state.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return _buildSimpleScreen(context, 'Edit Profile', 'Update your information', [
      Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Full Name', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'John Doe')),
          const SizedBox(height: 16),
          Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            state.setUserName(_nameCtrl.text.trim());
            state.setUserEmail(_emailCtrl.text.trim());
            state.goBack();
          },
          child: const Text('Save Changes'),
        ),
      ),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color fgColor;
  final Color mutedColor;
  final Color borderColor;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.fgColor,
    required this.mutedColor,
    required this.borderColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: isDestructive ? AppColors.destructive : mutedColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDestructive ? AppColors.destructive : fgColor))),
          if (value.isNotEmpty) Text(value, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: mutedColor),
        ]),
      ),
      Divider(height: 1, color: borderColor, indent: 16),
    ]);
  }
}
