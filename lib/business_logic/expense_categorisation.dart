import '../data/models/keyword.dart';

class ExpenseCategorisation {
  final List<CategoryKeyword> keywords;
  const ExpenseCategorisation(this.keywords);

  static const _commonKeywords = <String, String>{
    'petron': 'Fuel',
    'petronas': 'Fuel',
    'bhp': 'Fuel',
    'petrol': 'Fuel',
    'diesel': 'Fuel',
    'caltex': 'Fuel',
    'shell': 'Fuel',
    'fuel': 'Fuel',
    'food': 'Food',
    'restaurant': 'Food',
    'cafe': 'Food',
    'grocery': 'Food',
    'meal': 'Food',
    'toy': 'Entertainment',
    'toys': 'Entertainment',
    'movie': 'Entertainment',
    'cinema': 'Entertainment',
    'game': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'etc': 'Others',
  };

  String suggest(String description) {
    final text = description.toLowerCase();
    for (final keyword in keywords) {
      if (text.contains(keyword.word.toLowerCase())) return keyword.category;
    }
    for (final entry in _commonKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return 'Others';
  }
}
