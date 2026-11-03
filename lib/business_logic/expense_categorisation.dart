import '../data/models/keyword.dart';

class ExpenseCategorisation {
  final List<CategoryKeyword> keywords;
  const ExpenseCategorisation(this.keywords);

  static const _commonKeywords = <String, String>{
    'kfc': 'Food',
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

  String suggestReceipt(List<String> lines) {
    // Check the merchant header first, then item lines. Match whole words so
    // a payment word such as “cash” cannot match a shorter merchant keyword.
    final rules = {
      ..._commonKeywords,
      'coat': 'Shopping',
      'dress': 'Shopping',
      'handbag': 'Shopping',
      'crossbody bag': 'Shopping',
      'milk': 'Food',
      'muesli': 'Food',
      'chocolate': 'Food',
      'mushrooms': 'Food',
      'garlic': 'Food',
      'steaks': 'Food',
      'chicken': 'Food',
      'toast': 'Food',
      'earl grey': 'Food',
      for (final k in keywords) k.word.toLowerCase(): k.category,
    };
    for (final line in lines) {
      final words = line.toLowerCase().split(RegExp('[^a-z0-9]+'));
      final phrase = ' ${words.join(' ')} ';
      for (final rule in rules.entries) {
        final keyword = rule.key.replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
        if (keyword.isEmpty) continue;
        // OCR sometimes joins a merchant or product to the following noun.
        final joined = [
          'station',
          'restaurant',
          'receipt',
          'store',
        ].any((suffix) => words.contains('$keyword$suffix'));
        if (phrase.contains(' $keyword ') || joined) {
          return rule.value;
        }
      }
    }
    return 'Others';
  }
}
