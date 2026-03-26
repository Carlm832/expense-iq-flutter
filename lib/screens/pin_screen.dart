import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

// ─────────────────────────────────────────────
// PinEntryScreen  – shown on app launch if PIN is set
// ─────────────────────────────────────────────
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _entered = '';
  bool _error = false;

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = false;
    });
    if (_entered.length ==
        context.read<AppState>().pin.length) {
      _checkPin();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _checkPin() {
    final state = context.read<AppState>();
    if (_entered == state.pin) {
      state.unlockPin();
    } else {
      setState(() {
        _entered = '';
        _error = true;
      });
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
    final pinLen = state.pin.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 72, height: 72),
            const SizedBox(height: 16),
            Text('ExpenseIQ',
                style: GoogleFonts.dmSans(
                    fontSize: 22, fontWeight: FontWeight.w700, color: fgColor)),
            const SizedBox(height: 4),
            Text('Enter your PIN to continue',
                style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pinLen, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (_error ? AppColors.destructive : AppColors.primary)
                        : Colors.transparent,
                    border: Border.all(
                      color:
                          _error ? AppColors.destructive : AppColors.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Incorrect PIN. Try again.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.destructive)),
              ),
            const SizedBox(height: 32),
            // Numpad
            _Numpad(
                onKey: _onKey,
                onDelete: _onDelete,
                cardColor: cardColor,
                fgColor: fgColor,
                extraAction: state.isBiometricEnabled
                    ? IconButton(
                        icon: const Icon(Icons.fingerprint, size: 28),
                        onPressed: state.authenticateWithBiometrics,
                        color: AppColors.primary,
                      )
                    : null),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                await state.logout();
              },
              child: Text('Sign Out',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.destructive)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PinSetupScreen – create or change a PIN
// ─────────────────────────────────────────────
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  bool _mismatch = false;

  void _onKey(String digit) {
    setState(() {
      _mismatch = false;
      if (!_confirming) {
        if (_first.length < 4) _first += digit;
      } else {
        if (_confirm.length < 4) _confirm += digit;
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_confirming) {
        if (_confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        } else {
          _confirming = false;
          _first = '';
        }
      } else {
        if (_first.isNotEmpty) {
          _first = _first.substring(0, _first.length - 1);
        }
      }
    });
  }

  Future<void> _finish() async {
    if (_first == _confirm) {
      await context.read<AppState>().setPin(_first);
      if (mounted) context.read<AppState>().goBack();
    } else {
      setState(() {
        _confirm = '';
        _mismatch = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final current = _confirming ? _confirm : _first;
    const maxLen = 4;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.read<AppState>().goBack(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor)),
            child: Icon(Icons.arrow_back, size: 18, color: fgColor),
          ),
        ),
        title: Text('Set App PIN',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: fgColor)),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _confirming ? 'Confirm your PIN' : 'Choose a PIN (4 digits)',
              style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxLen, (i) {
                final filled = i < current.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (_mismatch
                            ? AppColors.destructive
                            : AppColors.primary)
                        : Colors.transparent,
                    border: Border.all(
                      color: _mismatch
                          ? AppColors.destructive
                          : AppColors.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_mismatch)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('PINs do not match. Try again.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.destructive)),
              ),
            const SizedBox(height: 32),
            _Numpad(onKey: _onKey, onDelete: _onDelete,
                cardColor: cardColor, fgColor: fgColor),
            if (!_confirming && _first.length == 4)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _confirming = true),
                    child: const Text('Continue'),
                  ),
                ),
              ),
            if (_confirming && _confirm.length == 4)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finish,
                    child: const Text('Save PIN'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared numpad widget
// ─────────────────────────────────────────────
class _Numpad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final Color cardColor;
  final Color fgColor;
  final Widget? extraAction;

  const _Numpad(
      {required this.onKey,
      required this.onDelete,
      required this.cardColor,
      required this.fgColor,
      this.extraAction});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          ...keys.map((k) => k.isEmpty
              ? (extraAction ?? const SizedBox())
              : _NumKey(label: k, onTap: () => onKey(k),
                  cardColor: cardColor, fgColor: fgColor)),
          _NumKey(
            icon: Icons.backspace_outlined,
            onTap: onDelete,
            cardColor: cardColor,
            fgColor: fgColor,
          ),
        ],
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color cardColor;
  final Color fgColor;

  const _NumKey(
      {this.label,
      this.icon,
      required this.onTap,
      required this.cardColor,
      required this.fgColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: label != null
              ? Text(label!,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: fgColor))
              : Icon(icon, size: 22, color: fgColor),
        ),
      ),
    );
  }
}
