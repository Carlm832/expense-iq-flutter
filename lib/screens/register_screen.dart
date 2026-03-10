import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  Map<String, String> _errors = {};

  bool _validate(AppState state) {
    final errors = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) errors['name'] = 'Name is required';
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email';
    }
    if (_passwordCtrl.text.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (_passwordCtrl.text.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      errors['confirmPassword'] = 'Passwords do not match';
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  Future<void> _handleRegister(AppState state) async {
    if (!_validate(state)) return;
    
    try {
      await state.registerWithEmail(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed.';
      if (e.code == 'email-already-in-use') msg = 'This email is already in use.';
      else if (e.code == 'weak-password') msg = 'The password is too weak.';
      setState(() => _errors = {'form': msg});
    } catch (e) {
      setState(() => _errors = {'form': 'An error occurred. Please try again.'});
    }
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
            children: [
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.read<AppState>().setCurrentScreen('login'),
                  icon: Icon(Icons.arrow_back, size: 16, color: mutedColor),
                  label: Text('Back to Sign In', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                ),
              ),
              const SizedBox(height: 16),
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
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person_add, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Create Account', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, color: fgColor)),
                        Text('Start tracking your expenses', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildField('Full Name', _nameCtrl, 'John Doe', Icons.person_outline, false, mutedColor, fgColor, _errors['name']),
                    const SizedBox(height: 16),
                    _buildField('Email', _emailCtrl, 'you@example.com', Icons.mail_outline, false, mutedColor, fgColor, _errors['email'], type: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    Text('Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon: Icon(Icons.lock_outline, size: 18, color: mutedColor),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 18, color: mutedColor),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        errorText: _errors['password'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Confirm Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: Icon(Icons.lock_outline, size: 18, color: mutedColor),
                        errorText: _errors['confirmPassword'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleRegister(state),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Create Account'),
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
                  Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                  GestureDetector(
                    onTap: () => context.read<AppState>().setCurrentScreen('login'),
                    child: Text('Sign in', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
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

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, bool obscure, Color muted, Color fg, String? error, {TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: muted),
          errorText: error,
        ),
      ),
    ]);
  }
}
