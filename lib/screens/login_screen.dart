import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  Map<String, String> _errors = {};

  bool _validate() {
    final errors = <String, String>{};
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
    }
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _handleLogin(AppState state) {
    if (!_validate()) return;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final name = state.getNameForEmail(email);
    if (name == null || !state.validateLogin(email, password)) {
      setState(() => _errors = {'form': 'Invalid email or password'});
      return;
    }
    state.login(name, email);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ExpenseIQ', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: fgColor)),
                      Text('Smart Finance Tracking', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Feature pills
              Wrap(
                spacing: 8, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FeaturePill(icon: Icons.document_scanner, label: 'Scan Receipts', color: AppColors.primary),
                  _FeaturePill(icon: Icons.bar_chart, label: 'Track Spending', color: AppColors.secondary),
                  _FeaturePill(icon: Icons.savings, label: 'Save More', color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 32),
              // Login card
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, color: fgColor)),
                    const SizedBox(height: 4),
                    Text('Sign in to manage your expenses', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                    const SizedBox(height: 24),
                    if (_errors['form'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_errors['form']!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.destructive, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                      ),
                    // Email
                    Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 18, color: mutedColor),
                        errorText: _errors['email'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password
                    Text('Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outline, size: 18, color: mutedColor),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 18, color: mutedColor),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        errorText: _errors['password'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogin(state),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Sign In'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                  GestureDetector(
                    onTap: () => context.read<AppState>().setCurrentScreen('register'),
                    child: Text('Sign up for free', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}
