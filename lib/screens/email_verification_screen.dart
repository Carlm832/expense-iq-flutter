import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';
import '../services/translations.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _handleResend(AppState state) async {
    setState(() => _isResending = true);
    try {
      await state.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleCheckStatus(AppState state) async {
    setState(() => _isChecking = true);
    try {
      await state.checkEmailVerificationStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify Your Email',
                      style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold, color: fgColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We have sent a verification link to:\n${state.userEmail}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: mutedColor, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : () => _handleCheckStatus(state),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isChecking 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text('I Have Verified', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isResending ? null : () => _handleResend(state),
                      child: _isResending 
                        ? const CircularProgressIndicator(strokeWidth: 2, size: 20)
                        : Text('Resend Verification Email', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => state.logout(),
                      child: Text('Back to Login', style: GoogleFonts.inter(color: mutedColor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
