import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import 'camera_screen.dart';
import '../services/translations.dart';
import '../app_state.dart';
import '../services/ocr_service.dart';

import 'package:flutter/services.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _scanFailed = false;
  String _statusMessage = 'Point camera at receipt';
  final _ocrService = OcrService();

  late AnimationController _scanAnimationCtrl;

  @override
  void initState() {
    super.initState();
    _scanAnimationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanAnimationCtrl.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isScanning = true;
      _scanFailed = false;
      _statusMessage = 'Picking image...';
    });
    _scanAnimationCtrl.repeat(reverse: true);

    try {
      XFile? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await Navigator.push<XFile>(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
      } else {
        imageFile = await _ocrService.pickImage(source);
      }

      if (imageFile == null) {
        _scanAnimationCtrl.stop();
        setState(() {
          _isScanning = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Analyzing receipt...';
      });

      final result = await _ocrService.processImage(imageFile);

      if (!mounted) return;

      if (result.success) {
        HapticFeedback.mediumImpact();
        setState(() {
          _statusMessage = 'Success!';
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        context.read<AppState>().setScreenArgs({
          'merchant': result.merchant,
          'amount': result.amount?.toStringAsFixed(2),
          'date': result.date,
          'currency': result.currency,
          'category': result.category,
          'fromScan': true,
        });
        _scanAnimationCtrl.stop();
        context.read<AppState>().setCurrentScreen('addExpense');
      } else {
        HapticFeedback.heavyImpact();
        _scanAnimationCtrl.stop();
        setState(() {
          _isScanning = false;
          _scanFailed = true;
          _statusMessage = 'Could not read receipt';
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _scanAnimationCtrl.stop();
      setState(() {
        _isScanning = false;
        _scanFailed = true;
        _statusMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;

    final lang = context.watch<AppState>().language;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Translations.t('nav_scan', lang),
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fgColor)),
              Text(Translations.t('scan_instructions', lang),
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _scanFailed
                              ? AppColors.destructive
                              : AppColors.primary.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildPreviewContent(fgColor, mutedColor, lang),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_scanFailed) ...[
                _ActionButton(
                  icon: Icons.refresh,
                  label: Translations.t('try_again', lang),
                  onPressed: () => setState(() {
                    _scanFailed = false;
                    _statusMessage = Translations.t('scan_instructions', lang);
                  }),
                  primary: true,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.edit,
                  label: Translations.t('enter_manually', lang),
                  onPressed: () =>
                      context.read<AppState>().setCurrentScreen('addExpense'),
                  primary: false,
                ),
              ] else if (!_isScanning) ...[
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: Translations.t('take_photo', lang),
                  onPressed: () => _scan(ImageSource.camera),
                  primary: true,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.photo_library,
                  label: Translations.t('from_gallery', lang),
                  onPressed: () => _scan(ImageSource.gallery),
                  primary: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(Color fgColor, Color mutedColor, String lang) {
    if (_isScanning) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Background pulsing icon
          const Opacity(
            opacity: 0.1,
            child:
                Icon(Icons.receipt_long, size: 120, color: AppColors.primary),
          ),

          // Animated Scanning Line
          AnimatedBuilder(
            animation: _scanAnimationCtrl,
            builder: (context, child) {
              return Positioned(
                top: _scanAnimationCtrl.value *
                    250, // Move down the container (approx height)
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration:
                      BoxDecoration(color: AppColors.primary, boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]),
                ),
              );
            },
          ),

          // Foreground Status
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_statusMessage,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fgColor),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      );
    }

    if (_scanFailed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.error_outline,
                size: 36, color: AppColors.destructive),
          ),
          const SizedBox(height: 20),
          Text(Translations.t('scan_failed', lang),
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500, color: fgColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(Translations.t('scan_failed_msg', lang),
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.document_scanner,
              size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(Translations.t('scan_instructions', lang),
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: fgColor),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('or choose from gallery',
            style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
        const SizedBox(height: 40),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CornerBracket(top: true, left: true),
            SizedBox(width: 80),
            _CornerBracket(top: true, left: false),
          ],
        ),
        const SizedBox(height: 40),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CornerBracket(top: false, left: true),
            SizedBox(width: 80),
            _CornerBracket(top: false, left: false),
          ],
        ),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool top;
  final bool left;
  const _CornerBracket({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      );
    }
  }
}
