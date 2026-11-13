import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/expense_categorisation.dart';
import 'package:final_year_project/data/models/keyword.dart';

void main() {
  const categorisation = ExpenseCategorisation([
    CategoryKeyword('grocery', 'Food'),
    CategoryKeyword('grab', 'Transport'),
  ]);

  test('merchant headers take priority over receipt items', () {
    expect(
      categorisation.suggestReceipt(['JAYA GROCER', 'Chicken 12.00']),
      'Shopping',
    );
    expect(categorisation.suggestReceipt(['TESCO', 'Milk 5.00']), 'Shopping');
    expect(categorisation.suggest('Grocery purchase'), 'Shopping');
    expect(categorisation.suggestReceipt(['KFC', 'Total 15.88']), 'Food');
  });

  test('recognises common English and Malay category keywords', () {
    for (final entry in {
      '99 Speedmart': 'Shopping',
      'Restoran nasi ayam': 'Food',
      'GrabFood dinner': 'Food',
      'PETROLSTATION RON95': 'Fuel',
      'BHPetrol': 'Fuel',
      'MRT ticket': 'Transport',
      'Parking fee': 'Transport',
      'Klinik pergigian': 'Healthcare',
      'Farmasi': 'Healthcare',
      'GSC cinema': 'Entertainment',
    }.entries) {
      expect(categorisation.suggest(entry.key), entry.value, reason: entry.key);
    }
  });

  test('does not match keyword fragments or payment information', () {
    for (final text in [
      'Shellfish',
      'Business invoice',
      'Cash payment',
      'Total RM 20.00',
    ]) {
      expect(categorisation.suggest(text), 'Others', reason: text);
    }
  });
}
