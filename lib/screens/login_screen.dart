import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../theme.dart';
import '../services/translations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  Map<String, String> _errors = {};

  bool _validate() {
    final errors = <String, String>{};
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final lang = context.read<AppState>().language;

    if (email.isEmpty) {
      errors['email'] = Translations.t('email_required', lang);
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = Translations.t('valid_email_required', lang);
    }
    if (password.isEmpty) {
      errors['password'] = Translations.t('password_required', lang);
    } else if (password.length < 6) {
      errors['password'] = Translations.t('password_min_length', lang);
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  Future<void> _handleLogin(AppState state) async {
    if (!_validate()) return;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() => _isLoading = true);
    try {
      await state.loginWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Invalid email or password.';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password.';
      } else if (e.code == 'too-many-requests') {
        msg = 'Too many failed attempts. Try again later.';
      }
      setState(() => _errors = {'form': msg});
    } catch (e) {
      setState(
          () => _errors = {'form': 'An unexpected error occurred.'});
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final lang = state.language;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
              : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo & Header
                _buildHeader(isDark, lang),
                const SizedBox(height: 48),
                // Login Card
                _buildLoginCard(state, isDark, lang),
                const SizedBox(height: 32),
                // Footer
                _buildFooter(state, isDark, lang),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String lang) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.account_balance_wallet_rounded, 
              color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Text('ExpenseIQ',
          style: GoogleFonts.dmSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkForeground : AppColors.foreground,
            letterSpacing: -1,
          )),
        const SizedBox(height: 8),
        Text(Translations.t('smart_finance_tracking', lang),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
          )),
      ],
    );
  }

  Widget _buildLoginCard(AppState state, bool isDark, String lang) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translations.t('login_welcome_back', lang),
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: fgColor,
            )),
          const SizedBox(height: 8),
          Text(Translations.t('login_subtitle', lang),
            style: GoogleFonts.inter(fontSize: 14, color: mutedColor)),
          const SizedBox(height: 32),
          
          if (_errors['form'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.destructive.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.destructive, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_errors['form']!,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.destructive, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Email
          _buildTextField(
            label: Translations.t('email', lang),
            controller: _emailCtrl,
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            error: _errors['email'],
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Password
          _buildTextField(
            label: Translations.t('password', lang),
            controller: _passwordCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            showPassword: _showPassword,
            onToggleVisibility: () => setState(() => _showPassword = !_showPassword),
            error: _errors['password'],
            isDark: isDark,
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => state.setCurrentScreen('forgot_password'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
              ),
              child: Text(Translations.t('login_forgot_password', lang),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(state),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(Translations.t('login_sign_in', lang), 
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: GoogleFonts.inter(fontSize: 12, color: mutedColor, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: borderColor)),
            ],
          ),
          const SizedBox(height: 24),

          // Google Sign In
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                  _errors = {};
                });
                try {
                  await state.signInWithGoogle();
                } on FirebaseAuthException catch (e) {
                  String msg = 'Google Sign-In failed.';
                  if (e.code == 'account-exists-with-different-credential') {
                    msg = 'An account already exists with the same email address but different sign-in credentials.';
                  } else if (e.code == 'network-request-failed') {
                    msg = 'Network error. Please check your connection.';
                  }
                  setState(() => _errors = {'form': msg});
                } catch (e) {
                  // If it's not a cancellation, show a generic error
                  // (Cancellation is handled by not throwing/rethrowing in app_state if null)
                  if (e.toString().contains('canceled')) {
                    // Do nothing for simple cancellation
                  } else {
                    setState(() => _errors = {'form': 'Google Sign-In failed. Please try again.'});
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_G_logo.svg/24px-Google_G_logo.svg.png', height: 20),
                  const SizedBox(width: 12),
                  Text('Sign in with Google', 
                    style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: fgColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? showPassword,
    VoidCallback? onToggleVisibility,
    String? error,
    required bool isDark,
  }) {
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && (showPassword == false),
          style: GoogleFonts.inter(fontSize: 15, color: fgColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: mutedColor, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: mutedColor),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(showPassword! ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: mutedColor),
              onPressed: onToggleVisibility,
            ) : null,
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            errorText: error,
            errorStyle: GoogleFonts.inter(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppState state, bool isDark, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(Translations.t('login_no_account', lang),
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => state.setCurrentScreen('register'),
          child: Text(Translations.t('login_signup_free', lang),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _error;
  bool _isSending = false;
  bool _isSent = false;

  Future<void> _handleReset(AppState state) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = Translations.t('valid_email_required', state.language));
      return;
    }

    setState(() {
      _error = null;
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isSending = false;
        _isSent = true;
      });
    } catch (e) {
      String msg = 'Failed to send reset email.';
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        msg = 'No user found with this email.';
      }
      setState(() {
        _isSending = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = state.language;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
              : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => state.setCurrentScreen('login'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: fgColor),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 30, offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: _isSent ? _buildSuccessView(state, fgColor, mutedColor) : _buildResetForm(state, fgColor, mutedColor, lang, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppState state, Color fgColor, Color mutedColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.secondary, size: 40),
        ),
        const SizedBox(height: 32),
        Text('Check your email',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold, color: fgColor)),
        const SizedBox(height: 12),
        Text('We have sent a password recovery link to ${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: mutedColor, height: 1.5)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => state.setCurrentScreen('login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Return to Login', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(AppState state, Color fgColor, Color mutedColor, String lang, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reset Password',
          style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold, color: fgColor)),
        const SizedBox(height: 8),
        Text('Enter your email and we\'ll send you instructions to reset your password.',
          style: GoogleFonts.inter(fontSize: 14, color: mutedColor, height: 1.5)),
        const SizedBox(height: 32),
        
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_error!, style: GoogleFonts.inter(color: AppColors.destructive, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 24),
        ],

        _buildTextField(
          label: Translations.t('email', lang),
          controller: _emailCtrl,
          hint: 'you@example.com',
          icon: Icons.alternate_email_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSending ? null : () => _handleReset(state),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSending 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text('Send Reset Link', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 15, color: fgColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: mutedColor, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: mutedColor),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
