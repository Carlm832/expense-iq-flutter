import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

Widget _buildSimpleScreen(BuildContext context, String title, String subtitle,
    List<Widget> children) {
  final state = context.read<AppState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
  final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
  final mutedColor =
      isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor)),
                child: Icon(Icons.arrow_back, size: 18, color: fgColor),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fgColor)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
            ]),
          ]),
        ),
        Expanded(
            child: SingleChildScrollView(
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
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return _buildSimpleScreen(context, 'Settings', 'App preferences', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        child: Column(children: [
          _SettingsTile(
              icon: Icons.language,
              label: 'Language',
              value: state.language,
              fgColor: fgColor,
              mutedColor: mutedColor,
              borderColor: borderColor,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Select Language'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['English', 'Turkish'].map((lang) => ListTile(
                        title: Text(lang),
                        selected: state.language == lang,
                        onTap: () {
                          state.setLanguage(lang);
                          Navigator.pop(ctx);
                        },
                      )).toList(),
                    ),
                  ),
                );
              }),
          _SettingsTile(
              icon: Icons.currency_exchange,
              label: 'Currency',
              value: state.currency,
              fgColor: fgColor,
              mutedColor: mutedColor,
              borderColor: borderColor,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Select Currency'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['TRY (₺)', 'USD (\$)', 'EUR (€)', 'GBP (£)'].map((curr) => ListTile(
                        title: Text(curr),
                        selected: state.currency == curr,
                        onTap: () {
                          state.setCurrency(curr);
                          Navigator.pop(ctx);
                        },
                      )).toList(),
                    ),
                  ),
                );
              }),
          _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: state.pushNotificationsEnabled ? 'On' : 'Off',
              fgColor: fgColor,
              mutedColor: mutedColor,
              borderColor: borderColor,
              onTap: () {
                state.setPushNotificationsEnabled(!state.pushNotificationsEnabled);
              }),
          _SettingsTile(
              icon: Icons.backup_outlined,
              label: 'Backup Data',
              value: '',
              fgColor: fgColor,
              mutedColor: mutedColor,
              borderColor: borderColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data backup is not available yet.')),
                );
              }),
          _SettingsTile(
              icon: Icons.delete_outline,
              label: 'Clear All Data',
              value: '',
              fgColor: fgColor,
              mutedColor: mutedColor,
              borderColor: borderColor,
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Data?'),
                    content: const Text('This will delete all your expenses, settings, and account data. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          state.clearAllData();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
                      ),
                    ],
                  ),
                );
              }),
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
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Appearance', 'Dark mode & themes', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Dark Mode',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: fgColor)),
                Text('Switch between light and dark theme',
                    style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
              ])),
          Switch(
              value: state.isDarkMode,
              onChanged: (_) => state.toggleDarkMode(),
              activeThumbColor: AppColors.primary),
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
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _ctrl.text =
        state.overallBudget > 0 ? state.overallBudget.toStringAsFixed(0) : '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return _buildSimpleScreen(
        context, 'Budget Manager', 'Set your monthly spending limit', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
              child: Text('Monthly Budget',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fgColor))),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: context.read<AppState>().currencySymbol,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (v) => state
                  .setOverallBudget(double.tryParse(v) ?? state.overallBudget),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final limit = double.tryParse(_ctrl.text) ?? 0;
            state.setOverallBudget(limit);
            state.goBack();
          },
          child: const Text('Save Budget'),
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
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final faqs = [
      (
        'How do I add an expense?',
        'Tap the + button on the dashboard or use the Add Expense form.'
      ),
      (
        'How do I scan a receipt?',
        'Use the Scan tab in the bottom navigation to scan receipts using your camera.'
      ),
      (
        'How do I set a budget?',
        'Go to Profile → Budget Manager to set spending limits per category.'
      ),
      (
        'How do I export my data?',
        'Go to History and tap the CSV button to export your transactions.'
      ),
    ];
    return _buildSimpleScreen(context, 'Help & Support', 'Get assistance', [
      ...faqs.map((faq) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq.$1,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fgColor)),
                    const SizedBox(height: 6),
                    Text(faq.$2,
                        style:
                            GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                  ]),
            ),
          )),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<AppState>().setCurrentScreen('contact_us');
          },
          icon: const Icon(Icons.support_agent, size: 18),
          label: const Text('Contact Us'),
        ),
      ),
    ]);
  }
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() => _isSending = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent successfully!')),
    );

    context.read<AppState>().goBack();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return _buildSimpleScreen(
        context, 'Contact Us', 'Send us a message directly', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Subject',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
                hintText: 'What is this regarding?'),
          ),
          const SizedBox(height: 16),
          Text('Message',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
                hintText: 'Describe your issue or feedback in detail...'),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSending ? null : _sendMessage,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Message'),
        ),
      ),
    ]);
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(
        context, 'Privacy & Security', 'Data protection', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Text(
          'Your data is stored locally on your device. We do not share your financial information with any third parties. All expense data is encrypted and protected.\n\nYou can delete all your data at any time from Settings → Clear All Data.',
          style:
              GoogleFonts.inter(fontSize: 13, color: mutedColor, height: 1.6),
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
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return _buildSimpleScreen(context, 'Payment Methods', 'Manage your cards', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(Icons.credit_card,
              size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No payment methods',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500, color: fgColor)),
          Text('Add a card to track linked expenses',
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
              textAlign: TextAlign.center),
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
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return _buildSimpleScreen(
        context, 'Edit Profile', 'Update your information', [
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Full Name',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'John Doe')),
          const SizedBox(height: 16),
          Text('Email',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          const SizedBox(height: 6),
          TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'you@example.com')),
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
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.fgColor,
    required this.mutedColor,
    required this.borderColor,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon,
                size: 18,
                color: isDestructive ? AppColors.destructive : mutedColor),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? AppColors.destructive : fgColor))),
            if (value.isNotEmpty)
              Text(value,
                  style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ]),
        ),
        Divider(height: 1, color: borderColor, indent: 16),
      ]),
    );
  }
}

