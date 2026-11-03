import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ReceiptRate = ({double rate, String date});

Future<ReceiptRate> latestReceiptRate(String currency) async {
  final response = await http
      .get(Uri.https('api.frankfurter.dev', '/v2/rate/$currency/MYR'))
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw const FormatException('Rate unavailable');
  }
  final data = jsonDecode(response.body);
  final rate = data['rate'];
  final date = data['date'];
  if (data['base'] != currency ||
      data['quote'] != 'MYR' ||
      rate is! num ||
      !rate.isFinite ||
      rate <= 0 ||
      date is! String ||
      DateTime.tryParse(date) == null) {
    throw const FormatException('Invalid exchange rate');
  }
  return (rate: rate.toDouble(), date: date);
}
