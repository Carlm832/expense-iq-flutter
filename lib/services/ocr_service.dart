import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  final String? merchant;
  final double? amount;
  final String? date; // ISO format YYYY-MM-DD
  final String rawText;
  final bool success;

  OcrResult({
    this.merchant,
    this.amount,
    this.date,
    required this.rawText,
    required this.success,
  });
}

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    return _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
    );
  }

  Future<OcrResult> processImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.isEmpty) {
        return OcrResult(rawText: '', success: false);
      }

      final lines = rawText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final merchant = _extractMerchant(lines);
      final amount = _extractTotal(lines);
      final date = _extractDate(lines);

      return OcrResult(
        merchant: merchant,
        amount: amount,
        date: date,
        rawText: rawText,
        success: merchant != null || amount != null,
      );
    } catch (e) {
      return OcrResult(rawText: '', success: false);
    }
  }

  String? _extractMerchant(List<String> lines) {
    // Merchant is usually in the first few lines, not a price or date
    for (final line in lines.take(5)) {
      if (_isPrice(line)) continue;
      if (_isDate(line)) continue;
      if (line.length < 3) continue;
      // Skip lines that look like addresses (contains numbers followed by letters)
      if (RegExp(r'^\d+\s+\w').hasMatch(line)) continue;
      // Skip lines that are all numbers
      if (RegExp(r'^[\d\s\-\/\.,]+$').hasMatch(line)) continue;
      return _capitalize(line);
    }
    return null;
  }

  double? _extractTotal(List<String> lines) {
    // Look for lines containing "total", "amount", "sum" keywords
    final keywords = ['total', 'amount due', 'grand total', 'balance', 'sum'];
    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          final price = _parsePrice(line);
          if (price != null) return price;
        }
      }
    }

    // Fallback: find the largest price value on the receipt (likely the total)
    double? largest;
    for (final line in lines) {
      final price = _parsePrice(line);
      if (price != null && price > 0) {
        if (largest == null || price > largest) {
          largest = price;
        }
      }
    }
    return largest;
  }

  String? _extractDate(List<String> lines) {
    // Date patterns: DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD, DD-MM-YY, etc.
    final datePatterns = [
      RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'), // DD/MM/YYYY or MM/DD/YYYY
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})'),  // DD/MM/YY
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (pattern.pattern.startsWith(r'(\d{4})')) {
              // YYYY-MM-DD
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final day = int.parse(match.group(3)!);
              if (_isValidDate(year, month, day)) {
                return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              }
            } else {
              // DD/MM/YYYY or MM/DD/YYYY
              final a = int.parse(match.group(1)!);
              final b = int.parse(match.group(2)!);
              int year = int.parse(match.group(3)!);
              if (year < 100) year += 2000;

              // Try DD/MM/YYYY first
              if (_isValidDate(year, b, a)) {
                return '${year.toString().padLeft(4, '0')}-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}';
              }
              // Try MM/DD/YYYY
              if (_isValidDate(year, a, b)) {
                return '${year.toString().padLeft(4, '0')}-${a.toString().padLeft(2, '0')}-${b.toString().padLeft(2, '0')}';
              }
            }
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  bool _isPrice(String line) => _parsePrice(line) != null;

  double? _parsePrice(String line) {
    final match = RegExp(r'[\$€£₺]?\s*(\d{1,6}[.,]\d{2})\b').firstMatch(line);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }

  bool _isDate(String line) {
    return RegExp(r'\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}').hasMatch(line);
  }

  bool _isValidDate(int year, int month, int day) {
    if (year < 2000 || year > 2030) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
