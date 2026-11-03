import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/receipt_reader.dart';

void main() {
  test(
    'identifies explicit currencies and leaves ambiguous dollars for review',
    () {
      expect(detectReceiptCurrency(r'Total S$12.80'), 'SGD');
      expect(detectReceiptCurrency('Total £5.08'), 'GBP');
      expect(detectReceiptCurrency(r'Denver, CO 80205 Total $15.88'), 'USD');
      expect(detectReceiptCurrency(r'Total $15.88'), r'$');
      expect(receiptTotal(['Total 1.234,56 EUR']), '1234.56');
      expect(receiptTotal(['Total TAX 12.30']), isNull);
    },
  );
  test('reads payable totals and ignores cash, change and item counts', () {
    expect(
      receiptTotal([
        'SUB TOTAL 20.00',
        'TOTAL 21.20',
        'CASH RM 50.00',
        'CHANGE 28.80',
      ]),
      '21.20',
    );
    expect(
      receiptTotal(['Total 10.00', 'Grand Total (RM) 1,234.56']),
      '1234.56',
    );
    expect(receiptTotal(['Jumlah Bayaran:', 'RM 24.70']), '24.70');
    expect(
      receiptTotal(['Total items: 2', 'Tax 5.00', 'Change 11.00']),
      isNull,
    );
    expect(receiptTotal(['Total 12.00', 'Total 15.00']), isNull);
    expect(receiptTotal(['Total -4.00']), isNull);
    expect(receiptTotal([r'Total $15,88']), '15.88');
    expect(receiptTotal(['Rounded Total (RM): 20.00']), '20.00');
    expect(receiptTotal(['Total [24] 53.28']), '53.28');
  });
}
