import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  final String? merchant;
  final double? amount;
  final String? date; // ISO format YYYY-MM-DD
  final String currency;
  final String rawText;
  final bool success;

  OcrResult({
    this.merchant,
    this.amount,
    this.date,
    this.currency = 'TRY',
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
      final currency = _extractCurrency(lines);

      return OcrResult(
        merchant: merchant,
        amount: amount,
        date: date,
        currency: currency,
        rawText: rawText,
        success: merchant != null || amount != null,
      );
    } catch (e) {
      return OcrResult(rawText: '', success: false);
    }
  }

  String? _extractMerchant(List<String> lines) {
    // Expanded ignore list for common receipt noise
    final ignoreKeywords = [
      'tax', 'vergi', 'fatur', 'tarih', 'saat', 'fis', 'fış', 'no:', 'tel:', 'adres',
      'mersis', 'ticaret', 'sicil', 'v.d.', 'toplam', 'total', 'kdv', 'matrah'
    ];

    for (final line in lines.take(10)) { // Check a bit deeper
      final lower = line.toLowerCase();
      if (_isPrice(line)) continue;
      if (_isDate(line)) continue;
      if (line.length < 3) continue;
      
      bool shouldIgnore = false;
      for (final keyword in ignoreKeywords) {
        if (lower.contains(keyword)) {
          shouldIgnore = true;
          break;
        }
      }
      if (shouldIgnore) continue;

      // Skip lines that look like addresses (contains numbers followed by letters frequently)
      if (RegExp(r'\d{3,}.*\w').hasMatch(line)) continue;
      // Skip lines that are all numbers or symbols
      if (RegExp(r'^[\d\s\-\/\.,\(\):]+$').hasMatch(line)) continue;
      
      return _capitalize(line);
    }
    return null;
  }

  double? _extractTotal(List<String> lines) {
    // Look for lines containing "total", "amount", "sum" keywords
    final keywords = [
      'total', 'amount due', 'grand total', 'balance', 'sum', 
      'genel toplam', 'toplam', 'tutar', 'odenen', 'ödenen'
    ];
    
    // Reverse search often works better for totals as they are at the bottom
    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          final price = _parsePrice(line);
          if (price != null) return price;
          
          // If the keyword line doesn't have the price, check the NEXT line in the original order 
          // (which is the PREVIOUS line in this reversed loop)
          // But wait, actually check the lines around it in the original list
          final originalIdx = lines.indexOf(line);
          if (originalIdx != -1) {
            // Check current line again with more aggressive parsing
            final p1 = _parsePriceAggr(line);
            if (p1 != null) return p1;

            // Check next line
            if (originalIdx + 1 < lines.length) {
              final p2 = _parsePriceAggr(lines[originalIdx + 1]);
              if (p2 != null) return p2;
            }
          }
        }
      }
    }

    // Fallback: find the largest price value on the receipt (likely the total)
    double? largest;
    for (final line in lines) {
      final price = _parsePriceAggr(line);
      if (price != null && price > 0 && price < 1000000) { // Sanity check
        if (largest == null || price > largest) {
          largest = price;
        }
      }
    }
    return largest;
  }

  double? _parsePrice(String line) {
    // Standard price regex
    final match = RegExp(r'[\$€£₺]?\s*(\d{1,6}[.,]\d{2})\b').firstMatch(line);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }

  double? _parsePriceAggr(String line) {
    // More aggressive price parsing with digit correction
    // Clean common OCR errors in what should be a price
    String cleaned = line.toUpperCase();
    cleaned = cleaned.replaceAll('S', '5');
    cleaned = cleaned.replaceAll('O', '0');
    cleaned = cleaned.replaceAll('L', '1');
    cleaned = cleaned.replaceAll('I', '1');
    cleaned = cleaned.replaceAll('B', '8');
    cleaned = cleaned.replaceAll('A', '4');

    // Look for pattern like 123.45 or 123,45 or 123 . 45
    final match = RegExp(r'(\d+)[\s.,]+(\d{2})\b').firstMatch(cleaned);
    if (match != null) {
      final whole = match.group(1)!;
      final decimal = match.group(2)!;
      return double.tryParse('$whole.$decimal');
    }

    // Look for single number that might be a price
    final matchSingle = RegExp(r'\b(\d{1,6})\b').firstMatch(cleaned);
    if (matchSingle != null) {
      return double.tryParse(matchSingle.group(1)!);
    }

    return null;
  }

  String? _extractDate(List<String> lines) {
    // Date patterns
    final datePatterns = [
      RegExp(r'(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{2})'), // DD/MM/YY
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (pattern.pattern.startsWith(r'(\d{4})')) {
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final day = int.parse(match.group(3)!);
              if (_isValidDate(year, month, day)) {
                return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              }
            } else {
              final a = int.parse(match.group(1)!);
              final b = int.parse(match.group(2)!);
              int year = int.parse(match.group(3)!);
              if (year < 100) year += 2000;

              if (_isValidDate(year, b, a)) {
                return '${year.toString().padLeft(4, '0')}-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}';
              }
              if (_isValidDate(year, a, b)) {
                return '${year.toString().padLeft(4, '0')}-${a.toString().padLeft(2, '0')}-${b.toString().padLeft(2, '0')}';
              }
            }
          } catch (_) {}
        }
      }
    }
    return null;
  }

  bool _isPrice(String line) => _parsePriceAggr(line) != null;

  bool _isDate(String line) {
    return RegExp(r'\d{1,2}[\/\.-]\d{1,2}[\/\.-]\d{2,4}').hasMatch(line);
  }

  bool _isValidDate(int year, int month, int day) {
    if (year < 2020 || year > 2030) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final words = s.split(' ');
    return words.map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  String _extractCurrency(List<String> lines) {
    for (final line in lines) {
      if (line.contains('\$')) return 'USD';
      if (line.contains('€')) return 'EUR';
      if (line.contains('£')) return 'GBP';
      if (line.contains('₺') || line.contains('TL')) return 'TRY';
    }
    return 'TRY'; // Default
  }

  void dispose() {
    _textRecognizer.close();
  }
}
