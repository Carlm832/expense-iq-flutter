// ignore_for_file: avoid_print
// Verification of the OCR logic with Batch 2 receipts

double? parsePrice(String line) {
  final match = RegExp(r'(\d{1,3}([.,]\d{3})*[.,]\d{2})\b').firstMatch(line);
  if (match == null) return null;
  
  String raw = match.group(1)!;
  final lastDot = raw.lastIndexOf('.');
  final lastComma = raw.lastIndexOf(',');
  
  if (lastDot > lastComma) {
    raw = raw.replaceAll(',', '');
  } else if (lastComma > lastDot) {
    raw = raw.replaceAll('.', '').replaceFirst(',', '.');
  }
  return double.tryParse(raw);
}

String? extractCurrency(List<String> lines) {
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (line.contains('\$')) return 'USD';
    if (line.contains('€')) return 'EUR';
    if (line.contains('£')) return 'GBP';
    if (line.contains('₺') || line.contains('TL')) return 'TRY';
    
    if (lower.contains('para cinsi')) {
      if (line.contains('EUR') || line.contains('Avro') || line.contains('Euro')) return 'EUR';
      if (line.contains('USD') || line.contains('Dolar')) return 'USD';
    }
  }
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (lower.contains('toplam') || lower.contains('kasa') || 
        lower.contains('girne') || lower.contains('lefkosa') || lower.contains('caddesi')) {
      return 'TRY';
    }
  }
  return null;
}

void main() {
  print("--- Testing Receipt 1 (Kiler Gida) ---");
  final lines1 = [
    "KILER GIDA LTD.",
    "TOPLAM 309,98",
    "KDV'LI TOPLAM 309,98"
  ];
  print("Price (TOPLAM): ${parsePrice("TOPLAM 309,98")}");
  print("Price (KDV'LI): ${parsePrice("KDV'LI TOPLAM 309,98")}");
  print("Currency: ${extractCurrency(lines1)}");

  print("\n--- Testing Receipt 2 (Kiler 4 Slip) ---");
  final lines2 = [
    "KILER 4",
    "LEFKOSA/KIBRIS",
    "309,98 TL",
    "ONAY KODU: OUJLVO"
  ];
  print("Price: ${parsePrice("309,98 TL")}");
  print("Currency: ${extractCurrency(lines2)}");

  print("\n--- Testing Receipt 3 (Cardplus ATM) ---");
  final lines3 = [
    "CARDPLUS",
    "AMOUNT : 2,000.00 TL",
    "TRANSCTION FEE : 0.00 TL"
  ];
  print("Price: ${parsePrice("AMOUNT : 2,000.00 TL")}");
  print("Currency: ${extractCurrency(lines3)}");
}
