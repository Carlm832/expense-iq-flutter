import 'dart:io';

// Mock classes to simulate ML Kit structure
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
                final verticalOverlap = (otherBox.top < keywordBox.bottom && otherBox.bottom > keywordBox.top);
                if (verticalOverlap && otherBox.left > keywordBox.left) {
                  final spatialPrice = _parsePriceAggr(otherLine.text);
                  if (spatialPrice != null) return spatialPrice;
                }
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

  String? _extractDate(List<String> lines) {
    final datePatterns = [
      RegExp(r'(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})'),
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{4})'),
      RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{2})'),
    ];
    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(0); // For testing simplicity
        }
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
    return null;
  }

  double? _parsePriceAggr(String line) {
    if (line.isEmpty) return null;
    if (!RegExp(r'\d').hasMatch(line)) return null;
    if (_isDate(line)) return null;
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
    }
    return double.tryParse(digitsOnly);
  }

  bool _isPrice(String s) {
    if (s.length > 15) return false;
    final letters = s.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length > 3) return false; // Too many letters for a pure price
    return _parsePriceAggr(s) != null;
  }
  bool _isDate(String s) => RegExp(r'\d{1,2}[\/\.-]\d{1,2}[\/\.-]\d{2,4}').hasMatch(s);
  String _capitalize(String s) => s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

void main() {
  final tester = OcrTester();
  final buffer = StringBuffer();

  void log(String msg) {
    buffer.writeln(msg);
  }

  // Test Sample 1: KILER 4
  log('--- Sample 1: KILER 4 ---');
  final blocks1 = [
    MockBlock([MockLine('KILER 4', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('19/03/2026', MockRect(10, 30, 100, 40))], MockRect(10, 30, 100, 40)),
    MockBlock([MockLine('309, 98 TL', MockRect(10, 60, 100, 70))], MockRect(10, 60, 100, 70)),
  ];
  final text1 = MockRecognizedText('KILER 4\n19/03/2026\n309, 98 TL', blocks1);
  log('Merchant: ${tester._extractMerchant(text1)}');
  log('Total: ${tester._extractTotal(text1)}');
  log('Date: ${tester._extractDate(text1.text.split('\n'))}');
  log('Currency: ${tester._extractCurrency(['309, 98 TL'])}');

  // Test Sample 2: CARDPLUS
  log('\n--- Sample 2: CARDPLUS ---');
  final blocks2 = [
    MockBlock([MockLine('CARDPLUS', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('12/03/2026', MockRect(10, 30, 100, 40))], MockRect(10, 30, 100, 40)),
    MockBlock([MockLine('AMOUNT :', MockRect(10, 50, 50, 60))], MockRect(10, 50, 50, 60)),
    MockBlock([MockLine('2,000.00 TL', MockRect(60, 50, 150, 60))], MockRect(60, 50, 150, 60)), // Horizontal Spatial
  ];
  final lines2 = ['CARDPLUS', '12/03/2026', 'AMOUNT : 2,000.00 TL'];
  final text2 = MockRecognizedText(lines2.join('\n'), blocks2);
  log('Merchant: ${tester._extractMerchant(text2)}');
  log('Total: ${tester._extractTotal(text2)}');
  log('Date: ${tester._extractDate(lines2)}');

  // Test Sample 3: KILER GIDA LTD
  log('\n--- Sample 3: KILER GIDA LTD ---');
  final blocks3 = [
    MockBlock([MockLine('KILER GIDA LTD.', MockRect(10, 10, 150, 20))], MockRect(10, 10, 150, 20)),
    MockBlock([MockLine('19/03/2026', MockRect(10, 30, 100, 40))], MockRect(10, 30, 100, 40)),
    MockBlock([MockLine('TOPLAM', MockRect(10, 100, 60, 110))], MockRect(10, 100, 60, 110)),
    MockBlock([MockLine('*309,98', MockRect(70, 100, 120, 110))], MockRect(70, 100, 120, 110)),
  ];
  final lines3 = ['KILER GIDA LTD.', '19/03/2026', 'TOPLAM', '*309,98'];
  final text3 = MockRecognizedText(lines3.join('\n'), blocks3);
  log('Merchant: ${tester._extractMerchant(text3)}');
  log('Total: ${tester._extractTotal(text3)}');
  log('Date: ${tester._extractDate(lines3)}');

  // Test Sample 4: LUNA FASHION
  log('\n--- Sample 4: LUNA FASHION ---');
  final blocks4 = [
    MockBlock([MockLine('LUNA FASHION', MockRect(10, 10, 100, 20))], MockRect(10, 10, 100, 20)),
    MockBlock([MockLine('14.03.2026', MockRect(10, 30, 100, 40))], MockRect(10, 30, 100, 40)),
    MockBlock([MockLine('Genel Toplam', MockRect(10, 100, 80, 110))], MockRect(10, 100, 80, 110)),
    MockBlock([MockLine('1.030,00', MockRect(100, 100, 150, 110))], MockRect(100, 100, 150, 110)),
  ];
  final lines4 = ['LUNA FASHION', '14.03.2026', 'Genel Toplam', '1.030,00'];
  final text4 = MockRecognizedText(lines4.join('\n'), blocks4);
  log('Merchant: ${tester._extractMerchant(text4)}');
  log('Total: ${tester._extractTotal(text4)}');
  log('Date: ${tester._extractDate(lines4)}');

  // Test Sample 5: NEAR EAST BANK
  log('\n--- Sample 5: NEAR EAST BANK (Dekont) ---');
  final blocks5 = [
    MockBlock([MockLine('NEAR EAST BANK', MockRect(10, 10, 150, 20))], MockRect(10, 10, 150, 20)),
    MockBlock([MockLine('06.03.2026', MockRect(10, 30, 100, 40))], MockRect(10, 30, 100, 40)),
    MockBlock([MockLine('Para cinsi', MockRect(10, 40, 60, 50))], MockRect(10, 40, 60, 50)),
    MockBlock([MockLine('EUR-Avro/Euro', MockRect(70, 40, 150, 50))], MockRect(70, 40, 150, 50)),
    MockBlock([MockLine('BORÇ', MockRect(10, 80, 50, 90))], MockRect(10, 80, 50, 90)),
    MockBlock([MockLine('600.00', MockRect(10, 95, 50, 105))], MockRect(10, 95, 50, 105)), // Vertical Spatial
  ];
  final lines5 = ['NEAR EAST BANK', '06.03.2026', 'Para cinsi EUR-Avro/Euro', 'BORÇ', '600.00'];
  final text5 = MockRecognizedText(lines5.join('\n'), blocks5);
  log('Merchant: ${tester._extractMerchant(text5)}');
  log('Total: ${tester._extractTotal(text5)}');
  log('Date: ${tester._extractDate(lines5)}');
  log('Currency: ${tester._extractCurrency(['Para cinsi EUR-Avro/Euro'])}');
  File('ocr_test_pure_results.txt').writeAsStringSync(buffer.toString());
}
