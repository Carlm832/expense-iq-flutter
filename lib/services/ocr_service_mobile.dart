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

      final receiptType = _detectReceiptType(lines);
      final merchant = _extractMerchant(recognizedText, receiptType: receiptType);
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

  /// Classify the receipt to guide extraction strategy.
  /// pos_slip: bank/card terminal receipt (TUTAR keyword, no item breakdown)
  /// bank_transfer: dekont / EFT receipt (EMV, to be payed, etc.)
  /// full_receipt: merchant POS roll (TOPLAM, KDV, ARATOPLAM, itemized list)
  String _detectReceiptType(List<String> lines) {
    final joined = lines.join(' ').toLowerCase();
    if (joined.contains('emv') || joined.contains('dekont') ||
        joined.contains('to be payed') || joined.contains('eft') ||
        joined.contains('havale') || joined.contains('borç')) {
      return 'bank_transfer';
    }
    // POS slip: has TUTAR/SATIS but NOT a full item list (no KDV line)
    if ((joined.contains('tutar') || joined.contains('satis')) &&
        !joined.contains('kdv') && !joined.contains('toplam')) {
      return 'pos_slip';
    }
    return 'full_receipt';
  }

  String? _extractMerchant(RecognizedText recognizedText, {String receiptType = 'full_receipt'}) {
    if (recognizedText.blocks.isEmpty) return null;

    // For POS slips and bank transfers, the merchant is listed BEFORE the terminal details
    // For full receipts, favour the very first block
    final topBlocks = recognizedText.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final ignoreList = [
      'tax', 'vergi', 'fatur', 'tarih', 'saat', 'fis', 'fış', 'no:', 'tel:', 'adres',
      'mersis', 'ticaret', 'sicil', 'v.d.', 'toplam', 'total', 'kdv', 'matrah',
      'cash', 'visa', 'mastercard', 'slip', 'pos', 'kredi',
      't.c', 'tc', 'odeme', 'ödenen', 'z rapor', 'z-rapor', 'tutar', 'vkn', 'mkn',
      'para cinsi', 'dekont', 'belge', 'fatura', 'musteri', 'müşteri'
    ];

    for (final block in topBlocks.take(6)) { 
      for (final line in block.lines) {
        final text = line.text.trim();
        final normalized = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        
        if (text.length < 3) continue;
        if (_isPrice(text)) continue;
        if (_isDate(text)) continue;
        
        bool shouldIgnore = false;
        for (final keyword in ignoreList) {
          if (normalized.contains(keyword.replaceAll(RegExp(r'[^a-z0-9]'), ''))) {
            shouldIgnore = true;
            break;
          }
        }
        if (shouldIgnore) continue;

        // Skip obvious contact info
        if (RegExp(r'\d{3,}.*\w|\w+@\w+\.\w+').hasMatch(text)) continue;
        if (RegExp(r'^[0-9\s\+\-\(\):]+$').hasMatch(text)) continue;

        String merchant = _capitalize(text);
        merchant = merchant.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
        
        if (merchant.length >= 3) return merchant;
      }
    }
    return null;
  }

  double? _extractTotal(RecognizedText recognizedText) {
    final List<_AmountCandidate> candidates = [];
    final totalKeywords = ['genel toplam', 'toplam', 'total', 'grand total', ' yekun', 'amount due', 'pay', 'due', 'odenen', 'ödenen', 'to be payed', 'to be paid', 'toplam net tutar', 'emv satis tutari', 'emv satış tutarı', 'borç'];
    final exclusionKeywords = ['ara toplam', 'subtotal', 'tax', 'kdv', 'k.d.v', 'discount', 'indirim', 'matrah', 'change', 'para ustu'];

    // 1. Identify all potential prices and their context
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final price = _parsePriceAggr(line.text);
        if (price != null && price > 0 && price < 1000000) {
          candidates.add(_AmountCandidate(
            value: price,
            text: line.text,
            boundingBox: line.boundingBox,
            isBottomHalf: line.boundingBox.top > 500, // Heuristic for typical receipt size
          ));
        }
      }
    }

    if (candidates.isEmpty) return null;

    // 2. Score each candidate based on multiple signals
    for (var candidate in candidates) {
      final lineTextLow = candidate.text.toLowerCase();
      
      // Signal 1: Proximity to "Total" keywords (High weight)
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final low = line.text.toLowerCase();
          if (_fuzzyMatch(low, totalKeywords)) {
            final keywordBox = line.boundingBox;
            // Immediate horizontal proximity (same line)
            final verticalOverlap = (candidate.boundingBox.top < keywordBox.bottom && candidate.boundingBox.bottom > keywordBox.top);
            if (verticalOverlap) {
              candidate.score += 50;
              if (candidate.boundingBox.left >= keywordBox.left) candidate.score += 30; // Usually to the right
            }
            // Vertical proximity (line below)
            if (candidate.boundingBox.top > keywordBox.top && (candidate.boundingBox.top - keywordBox.bottom).abs() < 50) {
              candidate.score += 40;
            }
          }
        }
      }

      // Signal 2: Exclusion of subtotals/taxes (Negative weight)
      if (_fuzzyMatch(lineTextLow, exclusionKeywords)) {
        candidate.score -= 100;
      }

      // Signal 3: Bottom position preference (Moderate weight)
      if (candidate.isBottomHalf) candidate.score += 20;

      // Signal 4: Large value preference (Low weight, totals are usually largest)
      // We'll normalize this after the loop
    }

    // Sort by score and then by value (tie-break with larger value)
    candidates.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      return b.value.compareTo(a.value);
    });

    // Filtering: If the highest score is negative and there are other options, ignore it
    final best = candidates.first;
    if (best.score <= -50 && candidates.length > 1) {
       // Search for largest positive or least negative
       return candidates.where((c) => c.score > -50).firstOrNull?.value ?? best.value;
    }

    return best.value;
  }

  bool _fuzzyMatch(String text, List<String> keywords) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final k in keywords) {
      final normK = k.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalized.contains(normK)) return true;
    }
    return false;
  }

  String suggestCategory(String? merchant) {
    if (merchant == null) return 'Shopping';
    final m = merchant.toLowerCase();

    // Food & Dining
    if (RegExp(r'market|grocery|gida|food|supermarket|migros|bim|a101|sok|carrefour|ikas|goldnuts|trading').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'restaur|cafe|coffee|starbucks|burger|pizza|yemek|kebap|doner|döner|lokanta|pastane|fırın|firin').hasMatch(m)) return 'Food & Dining';

    // Transport
    if (RegExp(r'taxi|uber|lyft|bolt|fuel|petrol|benzin|shell|bp|opet|station|transport|airport|akaryakıt|akaryakit|pompa').hasMatch(m)) return 'Transport';

    // Utilities — expanded for KKTC context
    if (RegExp(r'turkcell|vodafone|internet|wifi|utility|isik|kib.?tek|kibtek|elektrik|electric|su idaresi|water|telekom|telecom|mobile|tel:|kktc|tele').hasMatch(m)) return 'Utilities';
    if (RegExp(r'rent|kira|gas|dogalgaz|doğalgaz').hasMatch(m)) return 'Utilities';

    // Health
    if (RegExp(r'eczane|pharmacy|doktor|doctor|klinik|clinic|hastane|hospital|sağlık|saglik|dis|diş').hasMatch(m)) return 'Health';

    // Entertainment
    if (RegExp(r'cinema|netflix|spotify|game|steam|theater|sinema|eğlence|eglence').hasMatch(m)) return 'Entertainment';

    // Shopping
    if (RegExp(r'mall|shop|store|clothes|zara|h&m|ikea|amazon|ebay|trendyol|n11').hasMatch(m)) return 'Shopping';

    // Education
    if (RegExp(r'okul|school|univer|kolej|college|kurs|ders|kitap').hasMatch(m)) return 'Education';

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
    
    // 1. Pre-cleaning: remove currency symbols and whitespace between digits
    String cleaned = line.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY'), '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'(\d)\s+(\d)'), (m) => '${m[1]}${m[2]}');

    // 2. OCR character substitution (Apply only if it helps form a number)
    final substitutions = {'S': '5', 'O': '0', 'L': '1', 'I': '1', 'B': '8', 'A': '4', 'G': '6'};
    substitutions.forEach((key, value) {
      cleaned = cleaned.replaceAllMapped(RegExp('(?<=[\\d\\.,])$key|(?=[\\d\\.,])$key'), (m) => value);
    });
    
    // 3. Try to find a clean price pattern (digits + separator + 1-2 digits)
    final priceMatch = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{1,2})\b').firstMatch(cleaned);
    if (priceMatch != null) {
      final price = _parsePrice(priceMatch.group(1)!);
      if (price != null) return price;
    }

    // Safety check: A valid price shouldn't contain too many letters.
    final letters = cleaned.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length > 3) return null;

    // 4. Handle decimal/thousands separators for mixed formats
    final lastSeparatorIdx = cleaned.lastIndexOf(RegExp(r'[\.,]'));
    if (lastSeparatorIdx != -1) {
      String wholePart = cleaned.substring(0, lastSeparatorIdx).replaceAll(RegExp(r'[^0-9]'), '');
      String decimalPart = cleaned.substring(lastSeparatorIdx + 1).replaceAll(RegExp(r'[^0-9]'), '');
      
      if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
      if (decimalPart.isEmpty) decimalPart = '00';
      if (wholePart.length > 7) return null;
      
      return double.tryParse('$wholePart.$decimalPart');
    }

    // 5. Fallback for no separator (Assume last 2 digits are decimals)
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 2) {
      String whole = digits.substring(0, digits.length - 2);
      String dec = digits.substring(digits.length - 2);
      if (whole.length > 7) return null;
      return double.tryParse('$whole.$dec');
    }
    
    return double.tryParse(digits);
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

class _AmountCandidate {
  final double value;
  final String text;
  final Rect boundingBox;
  final bool isBottomHalf;
  int score = 0;

  _AmountCandidate({
    required this.value,
    required this.text,
    required this.boundingBox,
    required this.isBottomHalf,
  });
}
