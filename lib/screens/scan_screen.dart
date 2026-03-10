import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../app_state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  bool _scanFailed = false;

  Future<void> _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanFailed = false;
    });

    // Simulate OCR processing time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Simulate a 30% failure rate for demonstration purposes
    final bool isSuccess = DateTime.now().millisecond % 10 > 3;

    setState(() {
      _isScanning = false;
      if (isSuccess) {
        // OCR Success! Route to addExpense so it can be "auto-filled"
        // In a real app we would pass the extracted data
        context.read<AppState>().setCurrentScreen('addExpense');
      } else {
        _scanFailed = true;
      }
    });
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
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _scanFailed
                            ? AppColors.destructive
                            : AppColors.primary.withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isScanning) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text('Analyzing receipt...',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: fgColor)),
                        ] else if (_scanFailed) ...[
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                                color: AppColors.destructive
                                    .withValues(alpha: 0.1),
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
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: mutedColor)),
                        ] else ...[
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
                          Text('Point camera at receipt',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: fgColor),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('or choose from gallery',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: mutedColor)),
                        ]
                      ]),
                ),
              ),
              const SizedBox(height: 40),
              if (_scanFailed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _simulateScan,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AppState>().setCurrentScreen('addExpense');
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Enter Manually'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _simulateScan,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _simulateScan,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
