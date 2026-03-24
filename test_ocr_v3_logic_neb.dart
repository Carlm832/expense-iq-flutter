// ignore_for_file: avoid_print

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
      'total amount', 'balance due', 'amount due', 'borç', 'toplam net tutar'
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
                
                // 1. Vertical overlap (same horizontal plane) + RIGHT
                final verticalOverlap = (otherBox.top < keywordBox.bottom && otherBox.bottom > keywordBox.top);
                if (verticalOverlap && otherBox.left > keywordBox.left) {
                  final spatialPrice = _parsePriceAggr(otherLine.text);
                  if (spatialPrice != null) return spatialPrice;
                }

                // 2. Horizontal overlap (same vertical plane) + BELOW
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

  double? _parsePrice(String line) {
    final match = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{1,2})\b').firstMatch(line);
    if (match == null) return null;
    String raw = match.group(1)!;
    final lastDot = raw.lastIndexOf('.');
    final lastComma = raw.lastIndexOf(',');
    if (lastDot > lastComma) {
      raw = raw.replaceAll(',', '').replaceFirst('.', '.', lastDot);
    } else if (lastComma > lastDot) {
      raw = raw.replaceAll('.', '').replaceFirst(',', '.');
    }
    return double.tryParse(raw);
  }

  double? _parsePriceAggr(String line) {
    if (line.isEmpty) return null;
    
    final priceMatch = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{1,2})\b').firstMatch(line);
    if (priceMatch != null) {
      final price = _parsePrice(priceMatch.group(1)!);
      if (price != null) return price;
    }

    if (!RegExp(r'\d').hasMatch(line)) return null;

    String cleaned = line.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY'), '');
    cleaned = cleaned.replaceAll('S', '5').replaceAll('O', '0').replaceAll('L', '1').replaceAll('I', '1').replaceAll('B', '8').replaceAll('A', '4');
    
    final lastSeparatorIdx = cleaned.lastIndexOf(RegExp(r'[\.,]'));
    if (lastSeparatorIdx != -1) {
      String wholePart = cleaned.substring(0, lastSeparatorIdx).replaceAll(RegExp(r'\D'), '');
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

  // Test Case: NEAR EAST BANK (Dekont) - VERTICAL TEST
  print('--- Testing NEAR EAST BANK (Vertical Spatial) ---');
  final nebBlocks = [
    MockBlock([MockLine('NEAR EAST BANK', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('BORÇ', MockRect(200, 200, 250, 210))], MockRect(200, 200, 250, 210)),
    MockBlock([MockLine('600.00', MockRect(200, 215, 250, 225))], MockRect(200, 215, 250, 225)), // Directly below BORÇ
  ];
  final nebText = MockRecognizedText('NEAR EAST BANK\nBORÇ\n600.00', nebBlocks);
  final nebMerchant = tester._extractMerchant(nebText);
  final nebTotal = tester._extractTotal(nebText);
  print('Merchant: $nebMerchant (Expected: Near East Bank)');
  print('Total: $nebTotal (Expected: 600.0)');

  // Test Case: Same-line keyword and price
  print('\n--- Testing Same-line keyword and price ---');
  final sameLineBlocks = [
    MockBlock([MockLine('BORÇ 600.00', MockRect(200, 200, 300, 210))], MockRect(200, 200, 300, 210)),
  ];
  final sameLineText = MockRecognizedText('BORÇ 600.00', sameLineBlocks);
  final sameLineTotal = tester._extractTotal(sameLineText);
  print('Total: $sameLineTotal (Expected: 600.0)');
}
