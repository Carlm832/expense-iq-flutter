import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../app_state.dart';
import '../services/ocr_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  bool _scanFailed = false;
  String? _previewPath;
  String _statusMessage = 'Point camera at receipt';
  final _ocrService = OcrService();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _scanFailed = false;
      _statusMessage = 'Picking image...';
    });

    try {
      final imageFile = await _ocrService.pickImage(source);
      if (imageFile == null) {
        // User cancelled
        setState(() {
          _isScanning = false;
        });
        return;
      }

      setState(() {
        _previewPath = imageFile.path;
        _statusMessage = 'Analyzing receipt...';
      });

      final result = await _ocrService.processImage(imageFile);

      if (!mounted) return;

      if (result.success) {
        // Pass OCR result as screen args to the addExpense screen
        context.read<AppState>().setCurrentScreen(
          'addExpense',
          args: {
            'merchant': result.merchant,
            'amount': result.amount?.toStringAsFixed(2),
            'date': result.date,
            'fromScan': true,
          },
        );
      } else {
        setState(() {
          _isScanning = false;
          _scanFailed = true;
          _statusMessage = 'Could not read receipt';
        });
      }
    } catch (e) {
      if (!mounted) return;
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan Receipt',
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fgColor)),
              Text('Take a photo or upload a receipt',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
              const SizedBox(height: 24),

              // Scan preview box
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
                    child: _buildPreviewContent(fgColor, mutedColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              if (_scanFailed) ...[
                _ActionButton(
                  icon: Icons.refresh,
                  label: 'Try Again',
                  onPressed: () => setState(() {
                    _scanFailed = false;
                    _previewPath = null;
                    _statusMessage = 'Point camera at receipt';
                  }),
                  primary: true,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Enter Manually',
                  onPressed: () =>
                      context.read<AppState>().setCurrentScreen('addExpense'),
                  primary: false,
                ),
              ] else if (!_isScanning) ...[
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onPressed: () => _scan(ImageSource.camera),
                  primary: true,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.photo_library,
                  label: 'Choose from Gallery',
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

  Widget _buildPreviewContent(Color fgColor, Color mutedColor) {
    if (_isScanning) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_previewPath != null) ...[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_previewPath!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
                  // Dark overlay while processing
                  Container(color: Colors.black.withValues(alpha: 0.5)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(_statusMessage,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_statusMessage,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: fgColor),
                textAlign: TextAlign.center),
          ],
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
          Text('Could not read receipt',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fgColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Please try again or enter manually',
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
        ],
      );
    }

    // Default idle state
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child:
              const Icon(Icons.document_scanner, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('Point camera at receipt',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: fgColor),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('or choose from gallery',
            style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
        const SizedBox(height: 24),
        // Scan guide lines for aesthetics
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CornerBracket(top: true, left: true),
            const SizedBox(width: 80),
            _CornerBracket(top: true, left: false),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CornerBracket(top: false, left: true),
            const SizedBox(width: 80),
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
          top: top ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
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
    }
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
