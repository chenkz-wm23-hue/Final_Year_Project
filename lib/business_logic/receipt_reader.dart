import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

const receiptCurrencies = [
  'MYR',
  'USD',
  'GBP',
  'EUR',
  'SGD',
  'AUD',
  'CAD',
  'NZD',
  'HKD',
  'JPY',
  'CNY',
  'INR',
  'THB',
  'IDR',
  'PHP',
  'CHF',
];

String? detectReceiptCurrency(String text) {
  final upper = text.toUpperCase();
  for (final code in receiptCurrencies) {
    if (RegExp('\\b$code\\b').hasMatch(upper)) {
      return code == 'MYR' ? null : code;
    }
  }
  if (upper.contains('£')) return 'GBP';
  if (upper.contains('€')) return 'EUR';
  if (upper.contains('₹')) return 'INR';
  if (upper.contains('฿')) return 'THB';
  if (upper.contains('₱')) return 'PHP';
  if (upper.contains('¥')) return '¥';
  if (upper.contains(r'$')) {
    for (final entry in {
      r'US$': 'USD',
      r'S$': 'SGD',
      r'A$': 'AUD',
      r'C$': 'CAD',
      r'HK$': 'HKD',
      r'NZ$': 'NZD',
    }.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    if (RegExp(
      r'\b(?:AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|DC)\s+\d{5}\b',
    ).hasMatch(upper)) {
      return 'USD';
    }
    return r'$';
  }
  return null;
}

/// Prefer payable totals to subtotals, taxes, item prices and cash tendered.
String? receiptTotal(List<String> lines) {
  final label = RegExp(
    r'^\s*((?:grand|final|net|rounded)\s+total|total\s+(?:payable|due|amount)|amount\s+(?:due|payable)|jumlah\s+(?:besar|bayaran|keseluruhan)|total|jumlah)\b',
    caseSensitive: false,
  );
  final currencyToken = [
    r'RM|\(RM\)',
    ...receiptCurrencies,
    r'(?:US|HK|NZ|[SAC])?\$|[£€¥₹฿₱]',
  ].join('|');
  final amountOnly = RegExp(
    r'^\s*(?:\[\d+\]\s*)?[:=]?\s*(?:(?:' +
        currencyToken +
        r')\s*)?[:=]?\s*((?:\d{1,3}(?:[.,]\d{3})+|\d+)[.,]\d{2})\s*(?:' +
        currencyToken +
        r')?\s*$',
    caseSensitive: false,
  );
  var bestRank = 0;
  final candidates = <String>{};
  for (var i = 0; i < lines.length; i++) {
    final match = label.firstMatch(lines[i]);
    if (match == null) continue;
    var tail = lines[i].substring(match.end).trim();
    if (RegExp(
          r'^(?:[:=]?\s*(?:RM|MYR)?)$',
          caseSensitive: false,
        ).hasMatch(tail) &&
        i + 1 < lines.length) {
      tail = lines[i + 1];
    }
    final token = amountOnly.firstMatch(tail)?.group(1);
    if (token == null) continue;
    final cents = token.length - 3;
    final whole = token.substring(0, cents).replaceAll(RegExp('[.,]'), '');
    final raw = '$whole.${token.substring(cents + 1)}';
    if (double.parse(raw) <= 0) {
      continue;
    }
    final rank = match.group(1)!.contains(' ') ? 2 : 1;
    if (rank < bestRank) continue;
    if (rank > bestRank) {
      candidates.clear();
      bestRank = rank;
    }
    candidates.add(raw);
  }
  return candidates.length == 1 ? candidates.single : null;
}

Future<({String? total, String? foreignCurrency, List<String> lines})>
readReceipt(String path) async {
  final recognizer = TextRecognizer();
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    // OCR often separates the label and amount into different text blocks.
    final lines = result.blocks.expand((block) => block.lines).toList();
    final slopes = <double>[];
    for (final l in lines) {
      if (l.cornerPoints.length < 2) continue;
      final a = l.cornerPoints[0], b = l.cornerPoints[1];
      if (b.x - a.x < 40) continue;
      final slope = (b.y - a.y) / (b.x - a.x);
      if (slope.abs() < .5) slopes.add(slope);
    }
    slopes.sort();
    final slope = slopes.isEmpty ? 0.0 : slopes[slopes.length ~/ 2];
    double rowY(TextLine l) =>
        l.boundingBox.center.dy - slope * l.boundingBox.center.dx;
    lines.sort((a, b) => rowY(a).compareTo(rowY(b)));
    final rows = <String>[];
    var current = <TextLine>[];
    void finishRow() {
      current.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      rows.add(current.map((line) => line.text).join(' '));
      current = [];
    }

    for (final line in lines) {
      if (current.isNotEmpty &&
          (rowY(line) - rowY(current.first)).abs() >
              current.first.boundingBox.height * .55) {
        finishRow();
      }
      current.add(line);
    }
    if (current.isNotEmpty) finishRow();
    final text = result.text.toUpperCase();
    final currency = detectReceiptCurrency(text);
    return (
      total: receiptTotal(rows) ?? _confirmedCardTotal(lines),
      foreignCurrency: currency,
      lines: rows,
    );
  } finally {
    await recognizer.close();
  }
}

// Accept a displaced total only if a second card-payment row repeats it.
String? _confirmedCardTotal(List<TextLine> lines) {
  final matches = <String>{};
  final payment = RegExp(
    r'^(?:mastercard|visa|debit|credit card)\s+(?:sale|payment)$',
    caseSensitive: false,
  );
  final number = RegExp(r'^[£$]?\s*(\d+)[.,](\d{2})$');
  for (final label in lines.where(
    (l) => l.text.trim().toUpperCase() == 'TOTAL',
  )) {
    final box = label.boundingBox;
    final h = box.height;
    final nearby = lines
        .where(
          (l) =>
              l.boundingBox.left > box.right && number.hasMatch(l.text.trim()),
        )
        .toList();
    for (final card in lines.where((l) => payment.hasMatch(l.text.trim()))) {
      final gap = card.boundingBox.center.dy - box.center.dy;
      if (gap <= 0 || gap > 3 * h) continue;
      for (final first in nearby) {
        if ((first.boundingBox.center.dy - box.center.dy).abs() > 1.5 * h) {
          continue;
        }
        final repeated = nearby.any(
          (second) =>
              second.text.trim() == first.text.trim() &&
              second.boundingBox.center.dy > first.boundingBox.center.dy &&
              (second.boundingBox.center.dx - first.boundingBox.center.dx)
                      .abs() <
                  h &&
              (second.boundingBox.center.dy - card.boundingBox.center.dy)
                      .abs() <=
                  1.5 * h,
        );
        if (repeated) {
          final m = number.firstMatch(first.text.trim())!;
          matches.add('${m[1]}.${m[2]}');
        }
      }
    }
  }
  return matches.length == 1 ? matches.single : null;
}
