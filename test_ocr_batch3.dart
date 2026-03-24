// ignore_for_file: avoid_print
import 'dart:io';

class MockRect {
  final double left, top, right, bottom;
  MockRect(this.left, this.top, this.right, this.bottom);
}

class MockLine {
  final String text;
  final MockRect boundingBox;
  MockLine(this.text, this.boundingBox);
}

class MockBlock {
  final List<MockLine> lines;
  final MockRect boundingBox;
  MockBlock(this.lines, this.boundingBox);
}

class MockRecognizedText {
  final String text;
  final List<MockBlock> blocks;
  MockRecognizedText(this.text, this.blocks);
}

class OcrTester {
  String? _extractMerchant(MockRecognizedText r) {
    if (r.blocks.isEmpty) return null;
    final topBlocks = r.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    final ignoreKeywords = [
      'tax', 'vergi', 'fatur', 'tarih', 'saat', 'fis', 'fış', 'no:', 'tel:', 'adres',
      'mersis', 'ticaret', 'sicil', 'v.d.', 'toplam', 'total', 'kdv', 'matrah',
      'cash', 'visa', 'mastercard', 'slip', 'pos', 'kredi',
      't.c', 'tc', 'odeme', 'ödenen', 'z rapor', 'z-rapor', 'tutar', 'vkn', 'mkn',
      'para cinsi', 'dekont', 'belge', 'fatura', 'musteri', 'müşteri'
    ];
    for (final block in topBlocks.take(5)) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final lower = text.toLowerCase();
        if (text.length < 3) continue;
        if (_isPrice(text)) continue;
        if (_isDate(text)) continue;
        bool shouldIgnore = false;
        for (final keyword in ignoreKeywords) {
          if (lower.contains(keyword)) { shouldIgnore = true; break; }
        }
        if (shouldIgnore) continue;
        if (RegExp(r'\d{3,}.*\w').hasMatch(text)) continue;
        if (RegExp(r'^[\d\s\-\/\.,\(\):]+$').hasMatch(text)) continue;
        String merchant = _capitalize(text);
        merchant = merchant.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
        if (merchant.length >= 3) return merchant;
      }
    }
    return null;
  }

  double? _extractTotal(MockRecognizedText r) {
    // High priority: final bill keywords
    final highPriority = ['to be payed', 'to be paid', 'genel toplam', 'borç', 'emv satis tutari', 'emv satış tutarı'];
    // General keywords
    final general = ['toplam', 'tutar', 'top', 'odenen', 'ödenen', 'net tutar', 'total', 'grand total', 'amount due', 'invoices amount', 'amount collected'];

    for (final keywords in [highPriority, general]) {
      for (final block in r.blocks) {
        for (final line in block.lines) {
          final lower = line.text.toLowerCase();
          for (final keyword in keywords) {
            if (lower.contains(keyword)) {
              final price = _parsePriceAggr(line.text);
              if (price != null) return price;
              final keywordBox = line.boundingBox;
              for (final otherBlock in r.blocks) {
                for (final otherLine in otherBlock.lines) {
                  if (otherLine == line) continue;
                  final ob = otherLine.boundingBox;
                  final vertOverlap = ob.top < keywordBox.bottom && ob.bottom > keywordBox.top;
                  if (vertOverlap && ob.left > keywordBox.left) {
                    final p = _parsePriceAggr(otherLine.text);
                    if (p != null) return p;
                  }
                  final horizOverlap = ob.left < keywordBox.right && ob.right > keywordBox.left;
                  if (horizOverlap && ob.top > keywordBox.bottom && (ob.top - keywordBox.bottom) < 80) {
                    final p = _parsePriceAggr(otherLine.text);
                    if (p != null) return p;
                  }
                }
              }
            }
          }
        }
      }
    }
    double? largest;
    for (final block in r.blocks) {
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
    if (RegExp(r'market|grocery|gida|food|supermarket|migros|bim|a101|sok|carrefour|ikas|goldnuts|trading').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'taxi|uber|lyft|bolt|fuel|petrol|benzin|shell|bp|opet|station|transport|airport|donerland|dönerland|doner').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'mall|shop|store|clothes|zara|h&m|ikea|amazon|ebay|trendyol').hasMatch(m)) return 'Shopping';
    if (RegExp(r'turkcell|vodafone|internet|wifi|utility|elektrik|electric|su|water|isik|telecom').hasMatch(m)) return 'Utilities';
    if (RegExp(r'cinema|netflix|spotify|game|steam|theater|sinema').hasMatch(m)) return 'Entertainment';
    if (RegExp(r'restaur|cafe|coffee|starbucks|burger|pizza|yemek|kebap').hasMatch(m)) return 'Food & Dining';
    return 'Shopping';
  }

  String? _extractDate(List<String> lines) {
    final patterns = [
      RegExp(r'(\d{4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,2})'),
      RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4})'),
      RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2})'),
    ];
    for (final line in lines) {
      for (final p in patterns) {
        final match = p.firstMatch(line);
        if (match != null) return match.group(0);
      }
    }
    return null;
  }

  String? _extractCurrency(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (line.contains('\$')) return 'USD';
      if (line.contains('€')) return 'EUR';
      if (line.contains('£')) return 'GBP';
      if (line.contains('₺') || line.contains('TL')) return 'TRY';
      if (lower.contains('para cinsi')) {
        if (line.contains('EUR') || line.contains('Avro') || line.contains('Euro')) return 'EUR';
        if (line.contains('USD') || line.contains('Dolar')) return 'USD';
        if (line.contains('TL') || line.contains('TRY')) return 'TRY';
      }
    }
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('toplam') || lower.contains('kasa') ||
          lower.contains('girne') || lower.contains('lefkosa') ||
          lower.contains('lefkoşa') || lower.contains('caddesi')) return 'TRY';
    }
    return null;
  }

  double? _parsePriceAggr(String line) {
    if (line.isEmpty) return null;
    if (!RegExp(r'\d').hasMatch(line)) return null;
    if (_isDate(line)) return null;

    // Step 1: Try thousands-grouped format: 1.030,00 / 2,000.00 / 1,015.00
    final groupedMatch = RegExp(r'(\d{1,3}([.,]\d{3})+[.,]\d{1,2})\b').firstMatch(line);
    if (groupedMatch != null) {
      final raw = groupedMatch.group(1)!;
      final lastDot = raw.lastIndexOf('.');
      final lastComma = raw.lastIndexOf(',');
      String normalized = raw;
      if (lastDot > lastComma) {
        normalized = raw.replaceAll(',', '');
      } else {
        normalized = raw.replaceAll('.', '').replaceFirst(',', '.');
      }
      final parsed = double.tryParse(normalized);
      if (parsed != null && parsed > 0) return parsed;
    }
    // Step 2: Plain decimal format: 319,33 / 108,00 / 1013.74
    final plainMatch = RegExp(r'(\d+)[.,](\d{1,2})\b').firstMatch(line);
    if (plainMatch != null) {
      final parsed = double.tryParse('${plainMatch.group(1)}.${plainMatch.group(2)}');
      if (parsed != null && parsed > 0) return parsed;
    }

    // Step 2: Aggressive fallback for asterisk-prefixed values like *108,00
    String cleaned = line.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY|\*'), '').trim();
    final lastSep = cleaned.lastIndexOf(RegExp(r'[,\.]'));
    if (lastSep != -1) {
      String whole = cleaned.substring(0, lastSep).replaceAll(RegExp(r'[,\.\s]'), '');
      String dec = cleaned.substring(lastSep + 1).replaceAll(RegExp(r'\D'), '');
      if (dec.length > 2) dec = dec.substring(0, 2);
      if (dec.isEmpty) dec = '00';
      if (whole.length > 7) return null; // Prevent reference/subscriber numbers
      final parsed = double.tryParse('$whole.$dec');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }


  bool _isPrice(String s) {
    if (s.length > 15) return false;
    final letters = s.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length > 3) return false;
    return _parsePriceAggr(s) != null;
  }

  bool _isDate(String s) => RegExp(r'\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4}').hasMatch(s) ||
      RegExp(r'\d{4}[\/\.\-]\d{1,2}[\/\.\-]\d{1,2}').hasMatch(s);

  String _capitalize(String s) => s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

void main() {
  final t = OcrTester();
  final buf = StringBuffer();
  void log(String msg) { buf.writeln(msg); print(msg); }

  // --- Sample 1: GOLDNUTS TRADING (own receipt) ---
  log('=== Sample 1: GOLDNUTS TRADING ===');
  final b1 = [
    MockBlock([MockLine('GOLDNUTS TRADING', MockRect(100, 10, 300, 25))], MockRect(100, 10, 300, 25)),
    MockBlock([MockLine('GOLDROCK TRADING LTD.', MockRect(100, 28, 300, 40))], MockRect(100, 28, 300, 40)),
    MockBlock([MockLine('21-03-2026', MockRect(10, 60, 120, 72))], MockRect(10, 60, 120, 72)),
    MockBlock([MockLine('SAAT 19:28', MockRect(10, 75, 120, 85))], MockRect(10, 75, 120, 85)),
    MockBlock([MockLine('ARATOPLAM', MockRect(10, 180, 120, 192))], MockRect(10, 180, 120, 192)),
    MockBlock([MockLine('*108,00', MockRect(200, 180, 300, 192))], MockRect(200, 180, 300, 192)),
    MockBlock([MockLine('KDV', MockRect(10, 195, 80, 207))], MockRect(10, 195, 80, 207)),
    MockBlock([MockLine('*5,14', MockRect(200, 195, 300, 207))], MockRect(200, 195, 300, 207)),
    MockBlock([MockLine('TOP', MockRect(10, 210, 60, 222))], MockRect(10, 210, 60, 222)),
    MockBlock([MockLine('*108,00', MockRect(200, 210, 300, 222))], MockRect(200, 210, 300, 222)),
  ];
  final lines1 = ['GOLDNUTS TRADING', 'GOLDROCK TRADING LTD.', '21-03-2026', 'ARATOPLAM *108,00', 'TOP *108,00'];
  final text1 = MockRecognizedText(lines1.join('\n'), b1);
  log('Merchant: ${t._extractMerchant(text1)}   (Expected: Goldnuts Trading)');
  log('Total:    ${t._extractTotal(text1)}   (Expected: 108.0)');
  log('Date:     ${t._extractDate(lines1)}   (Expected: 21-03-2026)');
  log('Currency: ${t._extractCurrency(lines1)}   (Expected: TRY)');
  log('Category: ${t.suggestCategory(t._extractMerchant(text1))}   (Expected: Food & Dining)');

  // --- Sample 2: KUZEY KIBRIS TURKCELL ---
  log('\n=== Sample 2: KUZEY KIBRIS TURKCELL ===');
  final b2 = [
    MockBlock([MockLine('KUZEY KIBRIS TURKCELL', MockRect(100, 30, 350, 45))], MockRect(100, 30, 350, 45)),
    MockBlock([MockLine('Kibris Mobile Telekomunikasyon Ltd.', MockRect(80, 48, 370, 60))], MockRect(80, 48, 370, 60)),
    MockBlock([MockLine('Date: 2026-01-19 11:58:43', MockRect(10, 100, 300, 112))], MockRect(10, 100, 300, 112)),
    MockBlock([MockLine('Invoices amount: 1013.74 TL', MockRect(10, 115, 300, 125))], MockRect(10, 115, 300, 125)),
    MockBlock([MockLine('Amount collected: 1020 TL', MockRect(10, 128, 300, 138))], MockRect(10, 128, 300, 138)),
    MockBlock([MockLine('To be payed: 1,015.00 TL', MockRect(10, 141, 300, 151))], MockRect(10, 141, 300, 151)),
  ];
  final lines2 = ['KUZEY KIBRIS TURKCELL', 'Date: 2026-01-19 11:58:43', 'Invoices amount: 1013.74 TL', 'To be payed: 1,015.00 TL'];
  final text2 = MockRecognizedText(lines2.join('\n'), b2);
  log('Merchant: ${t._extractMerchant(text2)}   (Expected: Kuzey Kibris Turkcell)');
  log('Total:    ${t._extractTotal(text2)}   (Expected: 1015.0)');
  log('Date:     ${t._extractDate(lines2)}   (Expected: 2026-01-19)');
  log('Currency: ${t._extractCurrency(lines2)}   (Expected: TRY)');
  log('Category: ${t.suggestCategory(t._extractMerchant(text2))}   (Expected: Utilities)');

  // --- Sample 3: DONERLAND (Halkbank slip) ---
  log('\n=== Sample 3: DONERLAND (Halkbank slip) ===');
  final b3 = [
    MockBlock([MockLine('DONERLAND', MockRect(100, 10, 250, 22))], MockRect(100, 10, 250, 22)),
    MockBlock([MockLine('LEFKOSA/LEFKOSA', MockRect(100, 25, 250, 35))], MockRect(100, 25, 250, 35)),
    MockBlock([MockLine('11/03/2026-22:10', MockRect(10, 50, 250, 62))], MockRect(10, 50, 250, 62)),
    MockBlock([MockLine('TUTAR', MockRect(10, 120, 100, 132))], MockRect(10, 120, 100, 132)),
    MockBlock([MockLine('250,00 TL', MockRect(10, 135, 200, 147))], MockRect(10, 135, 200, 147)), // below TUTAR
  ];
  final lines3 = ['DONERLAND', 'LEFKOSA/LEFKOSA', '11/03/2026-22:10', 'TUTAR', '250,00 TL'];
  final text3 = MockRecognizedText(lines3.join('\n'), b3);
  log('Merchant: ${t._extractMerchant(text3)}   (Expected: Donerland)');
  log('Total:    ${t._extractTotal(text3)}   (Expected: 250.0)');
  log('Date:     ${t._extractDate(lines3)}   (Expected: 11/03/2026)');
  log('Currency: ${t._extractCurrency(lines3)}   (Expected: TRY)');
  log('Category: ${t.suggestCategory(t._extractMerchant(text3))}   (Expected: Food & Dining)');

  // --- Sample 4: IKAS SUPERMARKET (Cardplus slip) ---
  log('\n=== Sample 4: IKAS SUPERMARKET (Cardplus slip) ===');
  final b4 = [
    MockBlock([MockLine('IKAS SUPERMARKET', MockRect(100, 10, 300, 22))], MockRect(100, 10, 300, 22)),
    MockBlock([MockLine('24/03/2026-17:24', MockRect(10, 50, 250, 62))], MockRect(10, 50, 250, 62)),
    MockBlock([MockLine('TUTAR', MockRect(10, 120, 100, 132))], MockRect(10, 120, 100, 132)),
    MockBlock([MockLine('319,33 TL', MockRect(10, 135, 200, 147))], MockRect(10, 135, 200, 147)), // below TUTAR
  ];
  final lines4 = ['IKAS SUPERMARKET', '24/03/2026-17:24', 'TUTAR', '319,33 TL'];
  final text4 = MockRecognizedText(lines4.join('\n'), b4);
  log('Merchant: ${t._extractMerchant(text4)}   (Expected: Ikas Supermarket)');
  log('Total:    ${t._extractTotal(text4)}   (Expected: 319.33)');
  log('Date:     ${t._extractDate(lines4)}   (Expected: 24/03/2026)');
  log('Currency: ${t._extractCurrency(lines4)}   (Expected: TRY)');
  log('Category: ${t.suggestCategory(t._extractMerchant(text4))}   (Expected: Food & Dining)');

  // --- Sample 5: GOLDNUTS TRADING LTD (Garanti BBVA slip) ---
  log('\n=== Sample 5: GOLDNUTS TRADING LTD (Garanti BBVA slip) ===');
  final b5 = [
    MockBlock([MockLine('GOLDNUTS TRADING LTD.', MockRect(100, 10, 350, 22))], MockRect(100, 10, 350, 22)),
    MockBlock([MockLine('21/03/2026-19:28', MockRect(10, 60, 200, 72))], MockRect(10, 60, 200, 72)),
    MockBlock([MockLine('EMV SATIS TUTARI', MockRect(10, 120, 200, 132))], MockRect(10, 120, 200, 132)),
    MockBlock([MockLine('108,00 TL', MockRect(200, 120, 350, 132))], MockRect(200, 120, 350, 132)), // horizontal spatial
  ];
  final lines5 = ['GOLDNUTS TRADING LTD.', '21/03/2026-19:28', 'EMV SATIS TUTARI', '108,00 TL'];
  final text5 = MockRecognizedText(lines5.join('\n'), b5);
  log('Merchant: ${t._extractMerchant(text5)}   (Expected: Goldnuts Trading Ltd)');
  log('Total:    ${t._extractTotal(text5)}   (Expected: 108.0)');
  log('Date:     ${t._extractDate(lines5)}   (Expected: 21/03/2026)');
  log('Currency: ${t._extractCurrency(lines5)}   (Expected: TRY)');
  log('Category: ${t.suggestCategory(t._extractMerchant(text5))}   (Expected: Food & Dining)');

  File('ocr_batch3_results.txt').writeAsStringSync(buf.toString());
}
