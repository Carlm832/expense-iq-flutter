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
  String _detectReceiptType(List<String> lines) {
    final joined = lines.join(' ').toLowerCase();
    if (joined.contains('emv') || joined.contains('dekont') ||
        joined.contains('to be payed') || joined.contains('eft') ||
        joined.contains('havale') || joined.contains('borç')) {
      return 'bank_transfer';
    }
    if ((joined.contains('tutar') || joined.contains('satis')) &&
        !joined.contains('kdv') && !joined.contains('toplam')) {
      return 'pos_slip';
    }
    return 'full_receipt';
  }

  String? _extractMerchant(MockRecognizedText recognizedText, {String receiptType = 'full_receipt'}) {
    if (recognizedText.blocks.isEmpty) return null;

    final topBlocks = recognizedText.blocks.toList()
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
        
        print('Testing merchant candidate: "$text"');

        if (text.length < 3) { print('  Skipped: too short'); continue; }
        if (_isPrice(text)) { print('  Skipped: is price'); continue; }
        if (_isDate(text)) { print('  Skipped: is date'); continue; }

        bool shouldIgnore = false;
        for (final keyword in ignoreKeywords) {
          if (lower.contains(keyword)) {
            print('  Skipped: matches ignore keyword "$keyword"');
            shouldIgnore = true;
            break;
          }
        }
        if (shouldIgnore) continue;

        if (RegExp(r'\d{3,}.*\w').hasMatch(text)) { print('  Skipped: matches address/id regex'); continue; }
        if (RegExp(r'^[\d\s\-\/\.,\(\):]+$').hasMatch(text)) { print('  Skipped: matches numbers only regex'); continue; }

        String merchant = _capitalize(text);
        merchant = merchant.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
        
        if (merchant.length >= 3) {
          print('  ACCEPTED: $merchant');
          return merchant;
        }
      }
    }
    return null;
  }

  double? _extractTotal(MockRecognizedText recognizedText) {
    final highPriority = [
      'to be payed', 'to be paid', 'genel toplam', 'borç', 'toplam net tutar',
      'emv satis tutari', 'emv satış tutarı'
    ];
    final general = [
      'toplam', 'tutar', 'odenen', 'ödenen', 'net', 'yekun',
      'total', 'grand total', 'sum', 'due', 'pay', 'total amount',
      'balance due', 'amount due', 'invoices amount', 'amount collected', 'top'
    ];

    for (final keywords in [highPriority, general]) {
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
    }

    final allKeywords = [...highPriority, ...general];
    final lines = recognizedText.text.split('\n');
    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      for (final keyword in allKeywords) {
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

    if (RegExp(r'market|grocery|gida|food|supermarket|migros|bim|a101|sok|carrefour|ikas|goldnuts|trading').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'restaur|cafe|coffee|starbucks|burger|pizza|yemek|kebap|doner|döner|lokanta|pastane|fırın|firin').hasMatch(m)) return 'Food & Dining';
    if (RegExp(r'taxi|uber|lyft|bolt|fuel|petrol|benzin|shell|bp|opet|station|transport|airport|akaryakıt|akaryakit|pompa').hasMatch(m)) return 'Transport';
    if (RegExp(r'turkcell|vodafone|internet|wifi|utility|isik|kib.?tek|kibtek|elektrik|electric|su idaresi|water|telekom|telecom|mobile|tel:|kktc|tele').hasMatch(m)) return 'Utilities';
    if (RegExp(r'rent|kira|gas|dogalgaz|doğalgaz').hasMatch(m)) return 'Utilities';
    if (RegExp(r'eczane|pharmacy|doktor|doctor|klinik|clinic|hastane|hospital|sağlık|saglik|dis|diş').hasMatch(m)) return 'Health';
    if (RegExp(r'cinema|netflix|spotify|game|steam|theater|sinema|eğlence|eglence').hasMatch(m)) return 'Entertainment';
    if (RegExp(r'mall|shop|store|clothes|zara|h&m|ikea|amazon|ebay|trendyol|n11').hasMatch(m)) return 'Shopping';
    if (RegExp(r'okul|school|univer|kolej|college|kurs|ders|kitap').hasMatch(m)) return 'Education';

    return 'Shopping';
  }

  double? _parsePrice(String line) {
    final match = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{2})\b').firstMatch(line);
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
    if (!RegExp(r'\d').hasMatch(line)) return null;
    if (_isDate(line)) return null;
    
    final priceMatch = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{1,2})\b').firstMatch(line);
    if (priceMatch != null) {
      final price = _parsePrice(priceMatch.group(1)!);
      if (price != null) return price;
    }

    if (!RegExp(r'\d').hasMatch(line)) return null;

    String cleaned = line.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\$€£₺]|TL|TRY'), '');
    cleaned = cleaned.replaceAll('S', '5');
    cleaned = cleaned.replaceAll('O', '0');
    cleaned = cleaned.replaceAll('L', '1');
    cleaned = cleaned.replaceAll('I', '1');
    cleaned = cleaned.replaceAll('B', '8');
    cleaned = cleaned.replaceAll('A', '4');

    final lastSeparatorIdx = cleaned.lastIndexOf(RegExp(r'[\.,]'));
    if (lastSeparatorIdx != -1) {
      String wholePart = cleaned.substring(0, lastSeparatorIdx).replaceAll(RegExp(r'\D'), '');
      String decimalPart = cleaned.substring(lastSeparatorIdx + 1).replaceAll(RegExp(r'\D'), '');
      if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
      if (decimalPart.isEmpty) decimalPart = '00';
      if (wholePart.length > 7) return null;
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

  bool _isPrice(String line) {
    if (line.length > 15) return false;
    final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length > 3) return false;
    return _parsePriceAggr(line) != null;
  }

  bool _isDate(String line) {
    return RegExp(r'\d{1,2}[\/\.-]\d{1,2}[\/\.-]\d{2,4}').hasMatch(line) ||
           RegExp(r'(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})').hasMatch(line);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final words = s.split(' ');
    return words.map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}

void main() {
  final t = OcrTester();
  
  print('=== Sample 6: TURKCELL NEW RECEIPT ===');
  final linesStr = [
    'KUZEY KIBRIS TURKCELL',
    'Kibris Mobiletelekomunikasyon Ltd.',
    'Bedreddin Demirel Cad. Salih Mecit',
    'Sk. No: 1',
    'Lefkosa,KKTC',
    'Terminal numarasi: 7000218',
    'Makbuz Numarasi: 4608359',
    'Referans numarasi: 25152452',
    'Tarih: 2026-03-21 18:22:18',
    'Abone Adi: Ed*** Mo*** O***',
    'Abone Numarasi: 01112249570',
    'T.Fatura Tutari: 119.66 TL',
    'Odenen Tutar: 119.66 TL',
    'Kalan Borc: 0.00 TL',
    'Fatura N. * S.Tarih * Fatura Tutari * Odenen',
    '110869986124* 16/03/2026 * 119.66 TL * 119.66 TL',
    'Ara Odeme: 0 TL',
    'Hesabiniza tutar yatirilincaya kadar makbuzunuzu',
    'saklayiniz.',
    '* KUZEY KIBRIS TURKCELL CAGRI MERKEZI: 533 *',
    'LEFKOSA TEL:(392) 2280960',
    'ISYERI NO: 501790000015008 POS NO: PS0371DO',
    'ISLEM NO:WG0002 BATCH NO:1112 21/03/2026-18:23',
    'Mode1:DESK3500 - Versiyon:306 - Islem:C1FD3V',
    'SATIS',
    '4407 **** **** 9994',
    'FAITH NJENGA',
    'TUTAR',
    '119,66 TL',
    'Visa Debit',
    'AID : A0000000031010',
    'CHIP REFERANS NO : 41DB1C2B8CE8736D',
    'ONAY KODU : 916955',
    'TUTAR KARSILIGI MAL VEYA HIZMETI ALDIM',
    'SIFRE KULLANILMISTIR',
    'BU BELGEYI SAKLAYINIZ'
  ];

  final blocks = <MockBlock>[];
  double y = 10;
  for (final l in linesStr) {
    blocks.add(MockBlock([MockLine(l, MockRect(10, y, 300, y+10))], MockRect(10, y, 300, y+10)));
    y += 15;
  }
  final text = MockRecognizedText(linesStr.join('\n'), blocks);

  final receiptType = t._detectReceiptType(linesStr);
  final merchant = t._extractMerchant(text, receiptType: receiptType);
  final total = t._extractTotal(text);
  final cat = t.suggestCategory(merchant);

  print('Receipt Type: $receiptType');
  print('Merchant: $merchant');
  print('Total:    $total');
  print('Category: $cat');
  print('--- Debug Prices ---');
  for (final l in linesStr) {
     final p = t._parsePriceAggr(l);
     if (p != null) print('Line "$l" parsed as: $p');
  }
}

