import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  final String? merchant;
  final double? amount;
  final String? date; // ISO format YYYY-MM-DD
  final String? currency;
  final String? category;
  final String rawText;
  final bool success;

  OcrResult({
    this.merchant,
    this.amount,
    this.date,
    this.currency,
    this.category,
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

      final merchant = _extractMerchant(recognizedText);
      final amount = _extractTotal(recognizedText);
      final date = _extractDate(lines);
      final currency = _extractCurrency(lines);
      final category = suggestCategory(merchant);

      return OcrResult(
        merchant: merchant,
        amount: amount,
        date: date,
        currency: currency,
        category: category,
        rawText: rawText,
        success: merchant != null || amount != null,
      );
    } catch (e) {
      return OcrResult(rawText: '', success: false);
    }
  }

  String? _extractMerchant(RecognizedText recognizedText) {
    // Favor the top-most, likely largest block for the merchant name
    if (recognizedText.blocks.isEmpty) return null;

    // Filter and sort blocks by top position (Y coordinate)
    final topBlocks = recognizedText.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final ignoreKeywords = [
      'tax', 'vergi', 'fatur', 'tarih', 'saat', 'fis', 'fış', 'no:', 'tel:', 'adres',
      'mersis', 'ticaret', 'sicil', 'v.d.', 'toplam', 'total', 'kdv', 'matrah',
      'cash', 'visa', 'mastercard', 'slip', 'pos', 'kredi',
      't.c', 'tc', 'odeme', 'ödenen', 'z rapor', 'z-rapor', 'tutar', 'vkn', 'mkn',
      'para cinsi', 'dekont', 'belge', 'fatura', 'musteri', 'müşteri'
    ];

    // Check the first 3 blocks primarily
    for (final block in topBlocks.take(5)) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final lower = text.toLowerCase();
        
        if (text.length < 3) continue;
        if (_isPrice(text)) continue;
        if (_isDate(text)) continue;
        
        bool shouldIgnore = false;
        for (final keyword in ignoreKeywords) {
          if (lower.contains(keyword)) {
            shouldIgnore = true;
            break;
          }
        }
        if (shouldIgnore) continue;

        // Skip lines that look like addresses or random numeric identifiers
        if (RegExp(r'\d{3,}.*\w').hasMatch(text)) continue;
        if (RegExp(r'^[\d\s\-\/\.,\(\):]+$').hasMatch(text)) continue;

        String merchant = _capitalize(text);
        // Clean up noise
        merchant = merchant.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
        
        if (merchant.length >= 3) return merchant;
      }
    }
    return null;
  }

  double? _extractTotal(RecognizedText recognizedText) {
    final keywords = [
      'genel toplam', 'toplam', 'tutar', 'odenen', 'ödenen', 'net', 'yekun', 'total', 'grand total', 'sum', 'due', 'pay',
      'total amount', 'balance due', 'amount due', 'borç', 'toplam net tutar'
    ];
    
    // Spatial search: Look for numbers to the RIGHT of a total keyword
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lower = line.text.toLowerCase();
        for (final keyword in keywords) {
          if (lower.contains(keyword)) {
            // 1. Try to find price in the same line
            final price = _parsePriceAggr(line.text);
            if (price != null) return price;

            // 2. Look for nearby lines (spatial correlation)
            final keywordBox = line.boundingBox;
            for (final otherBlock in recognizedText.blocks) {
              for (final otherLine in otherBlock.lines) {
                if (otherLine == line) continue;
                final otherBox = otherLine.boundingBox;
                
                // If the other line is roughly on the same horizontal plane (Y overlaps)
                // and to the RIGHT of the keyword line
                final verticalOverlap = (otherBox.top < keywordBox.bottom && otherBox.bottom > keywordBox.top);
                if (verticalOverlap && otherBox.left > keywordBox.left) {
                  final spatialPrice = _parsePriceAggr(otherLine.text);
                  if (spatialPrice != null) return spatialPrice;
                }

                // 3. Look BELOW the keyword (for table headers like bank receipts)
                // If it's horizontally aligned (X overlaps) and BELOW
                final horizontalOverlap = (otherBox.left < keywordBox.right && otherBox.right > keywordBox.left);
                if (horizontalOverlap && otherBox.top > keywordBox.top && (otherBox.top - keywordBox.bottom) < 50) {
                  final spatialPrice = _parsePriceAggr(otherLine.text);
                  if (spatialPrice != null) return spatialPrice;
                }
              }
            }
          }
        }
      }
    }

    // Fallback: search by keywords in raw text lines (legacy method)
    final lines = recognizedText.text.split('\n');
    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          final p = _parsePriceAggr(line);
          if (p != null) return p;
        }
      }
    }

    // Ultimate fallback: find the largest price value
    double? largest;
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final price = _parsePriceAggr(line.text);
        if (price != null && price > 0 && price < 1000000) {
          if (largest == null || price > largest) largest = price;
        }
      }
    }
    return largest;
  }

  String suggestCategory(String? merchant) {
    if (merchant == null) return 'Shopping';
    final m = merchant.toLowerCase();
    
    if (RegExp(r'market|grocery|gida|food|supermarket|migros|bim|a101|sok|carrefour').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'taxi|uber|lyft|bolt|fuel|petrol|benzin|shell|bp|opet|station|transport|airport').hasMatch(m)) return 'Transport';
    if (RegExp(r'mall|shop|store|clothes|zara|h&m|ikea|amazon|ebay|trendyol|n11').hasMatch(m)) return 'Shopping';
    if (RegExp(r'cinema|netflix|spotify|game|steam|theater|sinema|eglence').hasMatch(m)) return 'Entertainment';
    if (RegExp(r'rent|kira|eletric|water|gas|internet|wifi|utility|isik').hasMatch(m)) return 'Utilities';
    if (RegExp(r'restaur|cafe|coffee|starbucks|burger|pizza|yemek|kebap').hasMatch(m)) return 'Food & Dining';

    return 'Shopping'; // Default
  }

  double? _parsePrice(String line) {
    // Improved price regex to handle optional thousands separators
    // Matches 1.030,00 or 1,234.56 or 600,00
    final match = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{2})\b').firstMatch(line);
    if (match == null) return null;
    
    String raw = match.group(1)!;
    // If it has both . and , the last one is the decimal
    final lastDot = raw.lastIndexOf('.');
    final lastComma = raw.lastIndexOf(',');
    
    if (lastDot > lastComma) {
      // . is decimal, remove ,
      raw = raw.replaceAll(',', '').replaceFirst('.', '.', lastDot);
    } else if (lastComma > lastDot) {
      // , is decimal, remove .
      raw = raw.replaceAll('.', '').replaceFirst(',', '.');
    }
    
    return double.tryParse(raw);
  }

  double? _parsePriceAggr(String line) {
    if (line.isEmpty) return null;
    if (!RegExp(r'\d').hasMatch(line)) return null; // Must contain at least one digit
    if (_isDate(line)) return null; // CRITICAL: Skip dates
    
    // 1. Try to find a clean price pattern (digits + separator + 1-2 digits)
    // Matches 1.234,56 or 600,00 or 10.5
    final priceMatch = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{1,2})\b').firstMatch(line);
    if (priceMatch != null) {
      final price = _parsePrice(priceMatch.group(1)!);
      if (price != null) return price;
    }

    // 2. Fallback to aggressive parsing if no clean match
    // Only proceed if there are ORIGINAL digits to avoid turn letters like "BORÇ" into "80"
    if (!RegExp(r'\d').hasMatch(line)) return null;

    String cleaned = line.toUpperCase().trim();
    
    // Remove currency symbols and common noise
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY'), '');
    
    // OCR character correction
    cleaned = cleaned.replaceAll('S', '5');
    cleaned = cleaned.replaceAll('O', '0');
    cleaned = cleaned.replaceAll('L', '1');
    cleaned = cleaned.replaceAll('I', '1');
    cleaned = cleaned.replaceAll('B', '8');
    cleaned = cleaned.replaceAll('A', '4');

    final lastSeparatorIdx = cleaned.lastIndexOf(RegExp(r'[\.,]'));
    if (lastSeparatorIdx != -1) {
      // Strip everything except digits from the whole part
      String wholePart = cleaned.substring(0, lastSeparatorIdx).replaceAll(RegExp(r'\D'), '');
      String decimalPart = cleaned.substring(lastSeparatorIdx + 1).replaceAll(RegExp(r'\D'), '');
      if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
      if (decimalPart.isEmpty) decimalPart = '00';
      
      return double.tryParse('$wholePart.$decimalPart');
    }

    // Fallback for lines without a clear separator but containing digits
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 2) {
      // Assume last 2 digits are decimals if no separator found
      String whole = digitsOnly.substring(0, digitsOnly.length - 2);
      String dec = digitsOnly.substring(digitsOnly.length - 2);
      return double.tryParse('$whole.$dec');
    } else if (digitsOnly.isNotEmpty) {
      return double.tryParse(digitsOnly);
    }

    return null;
  }

  String? _extractDate(List<String> lines) {
    // Date patterns
    final datePatterns = [
      RegExp(r'(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{2})'), // DD/MM/YY
      // Word-based month: 12 Jan 2024 or 12-Ocak-2024
      RegExp(r'(\d{1,2})[\s\.\-]+([a-zA-Z]{3,})[\s\.\-]+(\d{2,4})'), 
    ];

    final monthNames = {
      'jan': 1, 'ocak': 1,
      'feb': 2, 'subat': 2, 'şubat': 2,
      'mar': 3, 'mart': 3,
      'apr': 4, 'nisan': 4,
      'may': 5, 'mayis': 5, 'mayıs': 5,
      'jun': 6, 'haziran': 6,
      'jul': 7, 'temmuz': 7,
      'aug': 8, 'agustos': 8, 'ağustos': 8,
      'sep': 9, 'eylul': 9, 'eylül': 9,
      'oct': 10, 'ekim': 10,
      'nov': 11, 'kasim': 11, 'kasım': 11,
      'dec': 12, 'aralik': 12, 'aralık': 12
    };

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
            } else if (pattern.pattern.contains(r'([a-zA-Z]{3,})')) {
                // Word-based month handling
                final dayStr = match.group(1)!;
                final monthStr = match.group(2)!.toLowerCase();
                final yearStr = match.group(3)!;
                
                int day = int.parse(dayStr);
                int year = int.parse(yearStr);
                if (year < 100) year += 2000;
                
                int month = 0;
                monthNames.forEach((key, val) {
                  if (monthStr.startsWith(key)) month = val;
                });

                if (month > 0 && _isValidDate(year, month, day)) {
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

  bool _isPrice(String line) {
    if (line.length > 15) return false;
    final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length > 3) return false; // Too many letters for a pure price
    return _parsePriceAggr(line) != null;
  }

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

  String? _extractCurrency(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (line.contains('\$')) return 'USD';
      if (line.contains('€')) return 'EUR';
      if (line.contains('£')) return 'GBP';
      if (line.contains('₺') || line.contains('TL')) return 'TRY';
      
      // Explicit labels
      if (lower.contains('para cinsi')) {
        if (line.contains('EUR') || line.contains('Avro') || line.contains('Euro')) return 'EUR';
        if (line.contains('USD') || line.contains('Dolar')) return 'USD';
        if (line.contains('TL') || line.contains('TRY')) return 'TRY';
      }
    }
    
    // Inference from keywords
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('toplam') || lower.contains('kasa') || 
          lower.contains('girne') || lower.contains('lefkosa') || 
          lower.contains('lefkoşa') || lower.contains('caddesi')) {
        return 'TRY';
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
