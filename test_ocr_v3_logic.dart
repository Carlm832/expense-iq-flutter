
// Mock classes to simulate ML Kit structure without dart:ui
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
  String? _extractMerchant(MockRecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return null;
    final topBlocks = recognizedText.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final ignoreKeywords = [
      'tax', 'vergi', 'fatur', 'tarih', 'saat', 'fis', 'fış', 'no:', 'tel:', 'adres',
      'mersis', 'ticaret', 'sicil', 'v.d.', 'toplam', 'total', 'kdv', 'matrah',
      'cash', 'card', 'visa', 'mastercard', 'slip', 'pos', 'kredi', 'bank',
      't.c', 'tc', 'odeme', 'ödenen', 'z rapor', 'z-rapor', 'tutar', 'vkn', 'mkn'
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
          if (lower.contains(keyword)) {
            shouldIgnore = true;
            break;
          }
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

  double? _extractTotal(MockRecognizedText recognizedText) {
    final keywords = [
      'genel toplam', 'toplam', 'tutar', 'odenen', 'ödenen', 'net', 'yekun', 'total', 'grand total', 'sum', 'due', 'pay',
      'total amount', 'balance due', 'amount due'
    ];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lower = line.text.toLowerCase();
        for (final keyword in keywords) {
          if (lower.contains(keyword)) {
            final price = _parsePriceAggr(line.text);
            if (price != null) return price;
            
            final keywordBox = line.boundingBox;
            for (final otherBlock in recognizedText.blocks) {
              for (final otherLine in otherBlock.lines) {
                if (otherLine == line) continue;
                final otherBox = otherLine.boundingBox;
                // Vertical overlap check
                final verticalOverlap = (otherBox.top < keywordBox.bottom && otherBox.bottom > keywordBox.top);
                if (verticalOverlap && otherBox.left > keywordBox.left) {
                  final spatialPrice = _parsePriceAggr(otherLine.text);
                  if (spatialPrice != null) return spatialPrice;
                }
              }
            }
          }
        }
      }
    }
    
    // Fallback search
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
    return 'Shopping';
  }

  double? _parsePriceAggr(String line) {
    String cleaned = line.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY'), '');
    cleaned = cleaned.replaceAll('S', '5').replaceAll('O', '0').replaceAll('L', '1').replaceAll('I', '1').replaceAll('B', '8').replaceAll('A', '4');
    final lastSeparatorIdx = cleaned.lastIndexOf(RegExp(r'[\.,]'));
    if (lastSeparatorIdx != -1) {
      String wholePart = cleaned.substring(0, lastSeparatorIdx).replaceAll(RegExp(r'[\.,\s]'), '');
      String decimalPart = cleaned.substring(lastSeparatorIdx + 1).replaceAll(RegExp(r'\D'), '');
      if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
      if (decimalPart.isEmpty) decimalPart = '00';
      return double.tryParse('$wholePart.$decimalPart');
    }
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 2) {
      String whole = digitsOnly.substring(0, digitsOnly.length - 2);
      String dec = digitsOnly.substring(digitsOnly.length - 2);
      return double.tryParse('$whole.$dec');
    } else if (digitsOnly.isNotEmpty) {
      return double.tryParse(digitsOnly);
    }
    return null;
  }

  bool _isPrice(String s) => _parsePriceAggr(s) != null;
  bool _isDate(String s) => RegExp(r'\d{1,2}[\/\.-]\d{1,2}[\/\.-]\d{2,4}').hasMatch(s);
  String _capitalize(String s) => s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

void main() {
  final tester = OcrTester();

  // Test Case 1: LUNA FASHION
  print('--- Testing LUNA FASHION ---');
  final lunaBlocks = [
    MockBlock([MockLine('LUNA FASHION', MockRect(100, 10, 300, 30))], MockRect(100, 10, 300, 30)),
    MockBlock([MockLine('Genel Toplam', MockRect(100, 200, 250, 220))], MockRect(100, 200, 250, 220)),
    MockBlock([MockLine('1.030,00', MockRect(300, 200, 400, 220))], MockRect(300, 200, 400, 220)),
  ];
  final lunaText = MockRecognizedText('LUNA FASHION\nGenel Toplam 1.030,00', lunaBlocks);
  final lunaMerchant = tester._extractMerchant(lunaText);
  final lunaTotal = tester._extractTotal(lunaText);
  final lunaCat = tester.suggestCategory(lunaMerchant);
  print('Merchant: $lunaMerchant (Expected: Luna Fashion)');
  print('Total: $lunaTotal (Expected: 1030.0)');
  print('Category: $lunaCat (Expected: Shopping)');

  // Test Case 2: KILER 4 / KILER GIDA
  print('\n--- Testing KILER 4 / GIDA ---');
  final kilerBlocks = [
    MockBlock([MockLine('KILER 4', MockRect(100, 10, 200, 30))], MockRect(100, 10, 200, 30)),
    MockBlock([MockLine('TOPLAM', MockRect(50, 200, 150, 220))], MockRect(50, 200, 150, 220)),
    MockBlock([MockLine('*309,98', MockRect(200, 200, 300, 220))], MockRect(200, 200, 300, 220)),
  ];
  final kilerText = MockRecognizedText('KILER 4\nTOPLAM *309,98', kilerBlocks);
  final kilerMerchant = tester._extractMerchant(kilerText);
  final kilerTotal = tester._extractTotal(kilerText);
  final kilerCat = tester.suggestCategory(kilerMerchant);
  print('Merchant: $kilerMerchant (Expected: Kiler 4)');
  print('Total: $kilerTotal (Expected: 309.98)');
  print('Category: $kilerCat (Expected: Food & Dining)');

   // Test Case 3: NEAR EAST BANK (Dekont)
  print('\n--- Testing NEAR EAST BANK ---');
  final nebBlocks = [
    MockBlock([MockLine('NEAR EAST BANK', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('BORÇ', MockRect(200, 200, 250, 210))], MockRect(200, 200, 250, 210)),
    MockBlock([MockLine('600.00', MockRect(200, 215, 250, 225))], MockRect(200, 215, 250, 225)), // Below BORÇ
  ];
  final nebText = MockRecognizedText('NEAR EAST BANK\nBORÇ\n600.00', nebBlocks);
  final nebMerchant = tester._extractMerchant(nebText);
  final nebTotal = tester._extractTotal(nebText);
  print('Merchant: $nebMerchant (Expected: Near East Bank)');
  print('Total: $nebTotal (Expected: 600.0)');

   // Test Case 4: CARDPLUS
  print('\n--- Testing CARDPLUS ---');
  final cardBlocks = [
    MockBlock([MockLine('CARDPLUS', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('AMOUNT', MockRect(50, 100, 100, 110))], MockRect(50, 100, 100, 110)),
    MockBlock([MockLine('2,000.00 TL', MockRect(200, 100, 300, 110))], MockRect(200, 100, 300, 110)), 
  ];
  final cardText = MockRecognizedText('CARDPLUS\nAMOUNT 2,000.00 TL', cardBlocks);
  final cardMerchant = tester._extractMerchant(cardText);
  final cardTotal = tester._extractTotal(cardText);
  print('Merchant: $cardMerchant (Expected: Cardplus)');
  print('Total: $cardTotal (Expected: 2000.0)');
}
